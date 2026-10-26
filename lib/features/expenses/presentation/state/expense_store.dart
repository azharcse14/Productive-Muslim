import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/locale_digits.dart';

/// Spending buckets framed by Islamic priorities: needs first, then family,
/// then sadaqah, with wants kept in check (no israf — Al-A'raf 7:31).
enum ExpenseCategory { need, family, sadaqah, want }

final class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as int,
    amount: j['amount'] as int,
    category: ExpenseCategory.values.byName(j['category'] as String),
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String? ?? '',
  );

  final int id;

  /// Whole currency units (taka) — avoids float rounding in totals.
  final int amount;
  final ExpenseCategory category;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category.name,
    'date': date.toIso8601String(),
    'note': note,
  };
}

/// Personal expense log (hisab). Persisted as one JSON string, mirroring
/// [FastingStore]'s prefs persistence.
final class ExpenseStore {
  ExpenseStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _key = 'expenses_v1';

  /// Records (or a whole payload) that couldn't be read, kept as a JSON list
  /// of raw strings so a save — which drops them from [_key] — never
  /// destroys the only copy. Every load retries them, so records written by
  /// a newer version come back after upgrading again.
  static const _unreadableKey = 'expenses_v1_unreadable_records';
  static const _budgetKey = 'expense_budget_v1';
  static const _categoryBudgetKey = 'expense_category_budgets_v1';

  final SharedPreferencesAsync _prefs;
  final DateTime Function() _now;

  /// Newest first.
  late final entries = signal(const <Expense>[]);
  late final loaded = signal(false);

  /// Monthly spending limit (same for every month); null = no budget.
  late final budget = signal<int?>(null);

  /// Per-category monthly limits (for sadaqah, a goal); absent = none.
  late final categoryBudgets = signal(const <ExpenseCategory, int>{});

  /// Largest accepted amount — keeps int totals far from overflow.
  static const maxAmount = 999999999999;

  /// Whole-unit amount from user text (Bengali/Arabic digits and ','
  /// grouping accepted); null unless 1..[maxAmount].
  static int? parseAmount(String text) {
    final v = int.tryParse(LocaleDigits.toAscii(text.trim()), radix: 10);
    return v == null || v <= 0 || v > maxAmount ? null : v;
  }

  /// "Now" on the app's clock (the location's wall clock when injected).
  DateTime now() => _now();

  Future<void>? _loading;

  /// Loads once per store; every mutation awaits it first, so a write can
  /// never land before (and be clobbered by, or clobber) the stored list.
  /// A failed load is forgotten, so the next call (or write) retries it.
  Future<void> load() => _loading ??= () async {
    try {
      await _load();
    } on Object {
      _loading = null;
      rethrow;
    }
  }();

  Future<void> _load() async {
    final stored = await _prefs.getString(_key);
    final unreadable = <String>[
      for (final r in _decodeList(await _prefs.getString(_unreadableKey)))
        if (r is String) r,
    ];
    final before = unreadable.length;
    final read = <Expense>[];
    if (stored != null) {
      try {
        for (final j in jsonDecode(stored) as List) {
          try {
            read.add(Expense.fromJson(j as Map<String, dynamic>));
          } on Object {
            // One bad record (e.g. a category from a newer version).
            final raw = jsonEncode(j);
            if (!unreadable.contains(raw)) {
              unreadable.add(raw);
            }
          }
        }
      } on Object {
        if (!unreadable.contains(stored)) {
          unreadable.add(stored); // whole payload unreadable
        }
      }
    }
    // Retry the kept records; any that read now rejoin the list.
    final recovered = <Expense>[];
    for (final raw in [...unreadable]) {
      try {
        recovered.add(Expense.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        unreadable.remove(raw);
      } on Object {
        // Still unreadable — keep it.
      }
    }
    if (unreadable.length != before || recovered.isNotEmpty) {
      await _prefs.setString(_unreadableKey, jsonEncode(unreadable));
    }
    if (recovered.isEmpty) {
      entries.value = read;
    } else {
      var list = read;
      for (final e in recovered) {
        list = _withEntry(list, e);
      }
      await _save(list);
    }
    budget.value = await _prefs.getInt(_budgetKey);
    final storedBudgets = await _prefs.getString(_categoryBudgetKey);
    if (storedBudgets != null) {
      try {
        categoryBudgets.value = {
          for (final MapEntry(:key, :value)
              in (jsonDecode(storedBudgets) as Map<String, dynamic>).entries)
            ExpenseCategory.values.byName(key): value as int,
        };
      } on Object {
        // Corrupt payload: no category budgets rather than a crash.
      }
    }
    loaded.value = true;
  }

  /// Sets the monthly budget; null or non-positive clears it.
  Future<void> setBudget(int? value) async {
    await load();
    if (value == null || value <= 0) {
      budget.value = null;
      await _prefs.remove(_budgetKey);
    } else {
      budget.value = value;
      await _prefs.setInt(_budgetKey, value);
    }
  }

  /// Adds an expense dated [date] (defaults to now). Non-positive amounts
  /// are ignored.
  Future<void> add({
    required int amount,
    required ExpenseCategory category,
    String note = '',
    DateTime? date,
  }) async {
    await load();
    if (amount <= 0 || amount > maxAmount) {
      return;
    }
    final e = Expense(
      id: entries.value.fold(0, (m, e) => e.id > m ? e.id : m) + 1,
      amount: amount,
      category: category,
      date: date ?? _now(),
      note: note.trim(),
    );
    final next = [e, ...entries.value]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _save(next);
  }

  /// Sets [category]'s monthly budget; null or non-positive clears it.
  Future<void> setCategoryBudget(ExpenseCategory category, int? value) async {
    await load();
    final next = Map.of(categoryBudgets.value)..remove(category);
    if (value != null && value > 0) {
      next[category] = value;
    }
    categoryBudgets.value = next;
    await _prefs.setString(
      _categoryBudgetKey,
      jsonEncode({for (final e in next.entries) e.key.name: e.value}),
    );
  }

  /// Replaces the entry with [id]'s fields (amount, category, note, date).
  /// Non-positive amounts are ignored.
  Future<void> update(
    int id, {
    required int amount,
    required ExpenseCategory category,
    required DateTime date,
    String note = '',
  }) async {
    await load();
    if (amount <= 0 || amount > maxAmount) {
      return;
    }
    final next = [
      for (final e in entries.value)
        if (e.id == id)
          Expense(
            id: id,
            amount: amount,
            category: category,
            date: date,
            note: note.trim(),
          )
        else
          e,
    ]..sort((a, b) => b.date.compareTo(a.date));
    await _save(next);
  }

  Future<void> remove(int id) async {
    await load();
    await _save([
      for (final e in entries.value)
        if (e.id != id) e,
    ]);
  }

  /// Puts a removed [expense] back (undo). Same fields; a fresh id only if
  /// a later add has taken its old one.
  Future<void> restore(Expense expense) async {
    await load();
    await _save(_withEntry(entries.value, expense));
  }

  /// [list] plus [e], re-ided when its id is taken, newest first.
  static List<Expense> _withEntry(List<Expense> list, Expense e) {
    final taken = list.any((x) => x.id == e.id);
    final entry = taken
        ? Expense(
            id: list.fold(0, (m, x) => x.id > m ? x.id : m) + 1,
            amount: e.amount,
            category: e.category,
            date: e.date,
            note: e.note,
          )
        : e;
    return [entry, ...list]..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Object?> _decodeList(String? raw) {
    if (raw == null) {
      return const [];
    }
    try {
      return jsonDecode(raw) as List<Object?>;
    } on Object {
      return const [];
    }
  }

  /// Shows [next] at once (a swiped-away row must leave the tree now) and
  /// rolls back if the write fails, so the list never shows unsaved data.
  Future<void> _save(List<Expense> next) async {
    final previous = entries.value;
    entries.value = next;
    try {
      await _prefs.setString(
        _key,
        jsonEncode([for (final e in next) e.toJson()]),
      );
    } on Object {
      entries.value = previous;
      rethrow;
    }
  }

  /// First day of the month [offset] months from the current one.
  DateTime month([int offset = 0]) {
    final n = _now();
    return DateTime(n.year, n.month + offset);
  }

  List<Expense> inMonth(DateTime month) => [
    for (final e in entries.value)
      if (e.date.year == month.year && e.date.month == month.month) e,
  ];

  /// Per-category totals for [month]; every category present (0 if none).
  Map<ExpenseCategory, int> totalsFor(DateTime month) {
    final totals = {for (final c in ExpenseCategory.values) c: 0};
    for (final e in inMonth(month)) {
      totals[e.category] = totals[e.category]! + e.amount;
    }
    return totals;
  }
}
