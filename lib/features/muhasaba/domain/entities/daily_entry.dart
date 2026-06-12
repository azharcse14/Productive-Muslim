/// One logged value for one tracker on one civil day.
/// yesNo: 1 = done; count: repetitions; duration: minutes.
final class DailyEntry {
  const DailyEntry({
    required this.itemId,
    required this.date,
    required this.value,
  });

  final String itemId;

  /// Date-only (y/m/d at the user's wall clock); time parts ignored.
  final DateTime date;
  final int value;

  @override
  bool operator ==(Object other) =>
      other is DailyEntry &&
      other.itemId == itemId &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day &&
      other.value == value;

  @override
  int get hashCode =>
      Object.hash(itemId, date.year, date.month, date.day, value);
}
