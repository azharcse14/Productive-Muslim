/// Bengali calendar (Bangladesh revised calendar, 2019 revision):
/// year starts 14 April (1 Boishakh); Boishakh–Ashwin are 31 days,
/// Kartik–Magh and Choitro 30 days, Falgun 29 (30 when the Gregorian
/// year containing Falgun is a leap year).
final class BanglaDate {
  const BanglaDate(this.year, this.month, this.day);

  /// Bangabda year.
  final int year;

  /// 1 = Boishakh … 12 = Choitro.
  final int month;
  final int day;

  static bool _isGregorianLeap(int y) =>
      (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  /// Month lengths for the Bengali year beginning in Gregorian [startYear]
  /// (Falgun falls in startYear+1).
  static List<int> _monthLengths(int startYear) => [
        31, 31, 31, 31, 31, 31, // Boishakh–Ashwin
        30, 30, 30, 30, // Kartik–Magh
        _isGregorianLeap(startYear + 1) ? 30 : 29, // Falgun
        30, // Choitro
      ];

  static BanglaDate fromGregorian(DateTime date) {
    // The Bengali year that began on/before this date.
    final startYear =
        (date.month > 4 || (date.month == 4 && date.day >= 14))
            ? date.year
            : date.year - 1;
    final start = DateTime(startYear, 4, 14);
    var remaining = DateTime(date.year, date.month, date.day)
        .difference(start)
        .inDays;
    final lengths = _monthLengths(startYear);
    var month = 1;
    for (final length in lengths) {
      if (remaining < length) {
        break;
      }
      remaining -= length;
      month++;
    }
    return BanglaDate(startYear - 593, month, remaining + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is BanglaDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'BanglaDate($day/$month/$year BS)';
}
