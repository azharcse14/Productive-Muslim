/// Spending buckets framed by Islamic priorities: needs first, then family,
/// then sadaqah, with wants kept in check (no israf — Al-A'raf 7:31).
/// Persisted by `.name`.
enum ExpenseCategory { need, family, sadaqah, want }

final class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  final int id;

  /// Minor currency units (cents / poisha, 2 decimals) — ints avoid float
  /// rounding in totals.
  final int amount;
  final ExpenseCategory category;

  /// Floating wall time (see `WallTime.floating`).
  final DateTime date;
  final String note;

  /// Everything but the id — equal for the same real-world entry.
  ({int amount, ExpenseCategory category, DateTime date, String note})
  get fields => (amount: amount, category: category, date: date, note: note);

  Expense withId(int id) => Expense(
    id: id,
    amount: amount,
    category: category,
    date: date,
    note: note,
  );
}
