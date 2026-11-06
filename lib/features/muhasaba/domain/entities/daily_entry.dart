/// One logged value for one tracker on one civil day.
/// yesNo: 1 = done; count: repetitions; duration: minutes.
final class DailyEntry {
  const DailyEntry({
    required this.itemId,
    required this.date,
    required this.value,
    this.target,
  });

  final String itemId;

  /// Date-only (y/m/d at the user's wall clock); time parts ignored.
  final DateTime date;
  final int value;

  /// The item's daily target stamped when this entry was first written
  /// (0 = no target) — the day is judged by it, not by a later target.
  /// Null = unstamped (or a value to write): the item's current target.
  final int? target;

  @override
  bool operator ==(Object other) =>
      other is DailyEntry &&
      other.itemId == itemId &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day &&
      other.value == value &&
      other.target == target;

  @override
  int get hashCode =>
      Object.hash(itemId, date.year, date.month, date.day, value, target);
}
