import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

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

  Future<void> load() async {
    final stored = await _prefs.getString(_key);
    if (stored != null) {
      try {
        entries.value = [
          for (final j in jsonDecode(stored) as List)
            Expense.fromJson(j as Map<String, dynamic>),
        ];
      } on Object {
        // Corrupt payload: start empty rather than crash, but keep the raw
        // value untouched until the next successful save overwrites it.
      }
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
    if (amount <= 0) {
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
    if (amount <= 0) {
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

  Future<void> remove(int id) => _save([
    for (final e in entries.value)
      if (e.id != id) e,
  ]);

  Future<void> _save(List<Expense> next) async {
    entries.value = next;
    await _prefs.setString(
      _key,
      jsonEncode([for (final e in next) e.toJson()]),
    );
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
