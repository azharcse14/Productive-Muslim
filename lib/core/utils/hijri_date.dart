/// In-house tabular Islamic (Hijri) calendar — civil epoch variant of the
/// widely used Kuwaiti algorithm (guide §3.1: no package for date math).
///
/// Tabular calendars are arithmetic approximations; actual moon-sighted
/// dates (e.g. Umm al-Qura) can differ by ±1 day. Good enough for the
/// header/calendar; Ramadan detection allows for this in callers.
final class HijriDate {
  const HijriDate(this.year, this.month, this.day)
      : assert(month >= 1 && month <= 12, 'month out of range'),
        assert(day >= 1 && day <= 30, 'day out of range');

  /// Hijri year (AH).
  final int year;

  /// 1 = Muharram … 9 = Ramadan … 12 = Dhul-Hijjah.
  final int month;
  final int day;

  static const ramadanMonth = 9;

  /// Civil-epoch JDN of 1 Muharram 1 AH (Friday, 16 July 622 Julian).
  static const _epoch = 1948440;

  /// 30-year tabular cycle = 10631 days.
  static const _cycleDays = 10631;

  /// Leap Hijri years within the 30-year cycle (11 of 30).
  static const _leapYearsInCycle = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};

  static bool isLeapYear(int year) =>
      _leapYearsInCycle.contains(((year - 1) % 30) + 1);

  /// 29/30 alternation; Dhul-Hijjah gets 30 in leap years.
  static int daysInMonth(int year, int month) {
    if (month == 12) {
      return isLeapYear(year) ? 30 : 29;
    }
    return month.isOdd ? 30 : 29;
  }

  static HijriDate fromGregorian(DateTime date) =>
      _fromJdn(_gregorianToJdn(date.year, date.month, date.day));

  DateTime toGregorian() => _jdnToGregorian(_toJdn());

  int _toJdn() {
    final priorCycles = (year - 1) ~/ 30;
    final yearInCycle = ((year - 1) % 30) + 1; // 1..30
    var days = priorCycles * _cycleDays;
    for (var y = 1; y < yearInCycle; y++) {
      days += _leapYearsInCycle.contains(y) ? 355 : 354;
    }
    for (var m = 1; m < month; m++) {
      // Within a year only month 12 varies, and m < month ≤ 12 never
      // includes a partial month-12 — but compute properly anyway.
      days += daysInMonth(priorCycles * 30 + yearInCycle, m);
    }
    return _epoch + days + (day - 1);
  }

  static HijriDate _fromJdn(int jdn) {
    var days = jdn - _epoch;
    var year = (days ~/ _cycleDays) * 30;
    days %= _cycleDays;
    var yearInCycle = 1;
    while (true) {
      final length = _leapYearsInCycle.contains(yearInCycle) ? 355 : 354;
      if (days < length) {
        break;
      }
      days -= length;
      yearInCycle++;
    }
    year += yearInCycle;
    var month = 1;
    while (days >= daysInMonth(year, month)) {
      days -= daysInMonth(year, month);
      month++;
    }
    return HijriDate(year, month, days + 1);
  }

  /// Standard Gregorian → Julian Day Number.
  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - ((153 * m + 2) ~/ 5) + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);
    return DateTime(year, month, day);
  }

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'HijriDate($day/$month/$year AH)';
}
