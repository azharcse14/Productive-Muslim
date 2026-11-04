import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/wall_time.dart';
import '../domain/entities/expense.dart';

/// The pre-database prefs keys (app versions before schema 5).
const legacyExpenseKeys = {
  _expensesKey,
  _unreadableKey,
  _budgetKey,
  _categoryBudgetKey,
  _legacyBudgetKey,
  _legacyCategoryBudgetKey,
  _minorUnitsKey,
};
const _expensesKey = 'expenses_v1';

/// Raw records (or a whole payload) an older version couldn't read.
const _unreadableKey = 'expenses_v1_unreadable_records';
const _budgetKey = 'expense_budget_v2';
const _categoryBudgetKey = 'expense_category_budgets_v2';

/// Whole-unit budgets, superseded by the v2 keys once [_minorUnitsKey] is
/// set.
const _legacyBudgetKey = 'expense_budget_v1';
const _legacyCategoryBudgetKey = 'expense_category_budgets_v1';
const _minorUnitsKey = 'expense_minor_units_migrated';

/// Stays in prefs (a setting, read by the repository).
const expenseCurrencyKey = 'expense_currency_v1';

/// What this import couldn't read, kept as a JSON list of raw strings for
/// manual recovery; never read back by the app.
const unimportedExpensesKey = 'expenses_unimported';

/// Copies the expense log and budgets from prefs into [db]'s `expenses` /
/// `expense_budgets` tables in one transaction, then removes the old keys.
/// A no-op when none is stored. Re-running after a failure is safe: rows
/// are written insert-or-replace and nothing is removed before the commit.
///
/// Legacy handling: whole-unit records (`amount`) and v1 budgets are ×100;
/// records an older version kept aside are retried (re-ided on an id
/// collision); unreadable records and budget payloads go to
/// [unimportedExpensesKey]. Pre-decimal data was all taka, so it stores
/// BDT as the currency when none is set.
Future<void> importLegacyExpenses(
  GeneratedDatabase db,
  SharedPreferencesAsync prefs,
) async {
  if ((await prefs.getKeys(allowList: legacyExpenseKeys)).isEmpty) {
    return;
  }
  final unimported = <String>[];
  var legacy = false;
  final read = <Expense>[];

  void readRecord(Object? j, String raw) {
    try {
      final map = j! as Map<String, dynamic>;
      final e = _fromJson(map);
      legacy |= !map.containsKey('amountMinor');
      final holder = read.where((x) => x.id == e.id).firstOrNull;
      if (holder == null) {
        read.add(e);
      } else if (holder.fields != e.fields) {
        read.add(e.withId(read.fold(0, (m, x) => x.id > m ? x.id : m) + 1));
      } // else: stored and kept aside both — once is enough.
    } on Object {
      unimported.add(raw);
    }
  }

  final stored = await prefs.getString(_expensesKey);
  if (stored != null) {
    try {
      for (final j in jsonDecode(stored) as List) {
        readRecord(j, jsonEncode(j));
      }
    } on Object {
      unimported.add(stored); // whole payload unreadable
    }
  }
  final keptAside = await prefs.getString(_unreadableKey);
  if (keptAside != null) {
    try {
      for (final raw in (jsonDecode(keptAside) as List).cast<String>()) {
        try {
          readRecord(jsonDecode(raw), raw);
        } on FormatException {
          unimported.add(raw);
        }
      }
    } on Object {
      unimported.add(keptAside);
    }
  }

  // Budgets: the v2 (minor-unit) keys once migrated, else v1 ×100.
  final migrated = await prefs.getBool(_minorUnitsKey) == true;
  final v1Budget = await prefs.getInt(_legacyBudgetKey);
  final v1Categories = await prefs.getString(_legacyCategoryBudgetKey);
  final budgets = <String, int>{};
  final total = migrated ? await prefs.getInt(_budgetKey) : v1Budget;
  if (total != null) {
    budgets['total'] = migrated ? total : total * 100;
  }
  final categories = migrated
      ? await prefs.getString(_categoryBudgetKey)
      : v1Categories;
  if (categories != null) {
    try {
      for (final MapEntry(:key, :value)
          in (jsonDecode(categories) as Map<String, dynamic>).entries) {
        // Unknown (newer) categories are kept as rows, unread until a
        // version knows them.
        if (value is int && key != 'total') {
          budgets[key] = migrated ? value : value * 100;
        }
      }
    } on Object {
      unimported.add(categories);
    }
  }

  if (await prefs.getString(expenseCurrencyKey) == null &&
      (legacy || v1Budget != null || v1Categories != null)) {
    await prefs.setString(expenseCurrencyKey, 'BDT');
  }
  await db.transaction(() async {
    for (final e in read) {
      await insertExpense(db, e);
    }
    for (final MapEntry(:key, :value) in budgets.entries) {
      await db.customInsert(
        'INSERT OR REPLACE INTO expense_budgets (key, amount) VALUES (?, ?)',
        variables: [Variable.withString(key), Variable.withInt(value)],
      );
    }
  });
  // Kept before any source key goes, so a failure here loses nothing.
  if (unimported.isNotEmpty) {
    final earlier = await prefs.getString(unimportedExpensesKey);
    await prefs.setString(
      unimportedExpensesKey,
      // A set: a re-run after a failed removal adds no duplicates.
      jsonEncode(
        {
          if (earlier != null) ...(jsonDecode(earlier) as List).cast<String>(),
          ...unimported,
        }.toList(),
      ),
    );
  }
  for (final key in legacyExpenseKeys) {
    await prefs.remove(key);
  }
}

/// Writes [e] as an `expenses` row, replacing one with its id.
Future<void> insertExpense(DatabaseConnectionUser db, Expense e) =>
    db.customInsert(
      'INSERT OR REPLACE INTO expenses (id, amount, category, date, note) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable.withInt(e.id),
        Variable.withInt(e.amount),
        Variable.withString(e.category.name),
        Variable.withInt(e.date.microsecondsSinceEpoch),
        Variable.withString(e.note),
      ],
    );

/// Reads both record formats: `amountMinor` (minor units) and the legacy
/// whole-unit `amount` (×100).
Expense _fromJson(Map<String, dynamic> j) => Expense(
  id: j['id'] as int,
  amount: switch (j['amountMinor']) {
    final int minor => minor,
    _ => (j['amount'] as int) * 100,
  },
  category: ExpenseCategory.values.byName(j['category'] as String),
  // Floating wall time (older records were stored device-local).
  date: DateTime.parse(j['date'] as String).floating,
  note: j['note'] as String? ?? '',
);
