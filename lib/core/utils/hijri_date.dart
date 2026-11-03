/// In-house tabular Islamic (Hijri) calendar — civil epoch variant of the
/// widely used Kuwaiti algorithm (guide §3.1: no package for date math).
///
/// Tabular calendars are arithmetic approximations; actual moon-sighted
/// dates (e.g. Umm al-Qura, or regional sighting such as Bangladesh) can
/// differ by a day or two; the user corrects this with a −2..+2 offset that
/// callers pass to [fromGregorian]/[toGregorian].
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
  static const shawwalMonth = 10;

  /// Hijri years whose Ramadan the community ended after 29 days ("Eid
  /// announced"). The tabular calendar always gives Ramadan 30 days; for
  /// these years its 30th day reads as 1 Shawwal and Shawwal absorbs the
  /// day (30 days), so Dhul-Qadah onwards is unchanged.
  ///
  /// A hook rather than a parameter so every conversion in the app follows
  /// it without each caller threading it through; the composition root
  /// points it at a signal, so a `computed` that converts a date re-runs
  /// when the set changes. Kept pure Dart: no signals import here.
  ///
  /// Process-wide: set once, first thing in `setupLocator`; tests that set
  /// it must reset it. Domain code that depends on it through
  /// [fromGregorian]/[daysInMonth]: `RamadanUtils` (roza day, length,
  /// month table), `RecommendedFasts` (Eid forbidden, Ramadan excluded),
  /// `IslamicDates` (calendar labels), `buildNotificationPlan` (sahri and
  /// iftar days) and the age calculator.
  // ponytail: process-wide hook; pass the set explicitly if a second
  // calendar (e.g. per-profile sighting) is ever needed.
  static Set<int> Function() shortRamadanYears = _noShortRamadans;

  static Set<int> _noShortRamadans() => const {};

  static bool _isShortRamadanMonth(int year, int month) =>
      (month == ramadanMonth || month == shawwalMonth) &&
      shortRamadanYears().contains(year);

  /// Civil-epoch JDN of 1 Muharram 1 AH (Friday, 16 July 622 Julian).
  static const _epoch = 1948440;

  /// 30-year tabular cycle = 10631 days.
  static const _cycleDays = 10631;

  /// Leap Hijri years within the 30-year cycle (11 of 30).
  static const _leapYearsInCycle = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};

  static bool isLeapYear(int year) =>
      _leapYearsInCycle.contains(((year - 1) % 30) + 1);

  /// Observed month length: the tabular one, except Ramadan (29) and
  /// Shawwal (30) in a [shortRamadanYears] year.
  static int daysInMonth(int year, int month) {
    if (_isShortRamadanMonth(year, month)) {
      return month == ramadanMonth ? 29 : 30;
    }
    return _tabularDaysInMonth(year, month);
  }

  /// 29/30 alternation; Dhul-Hijjah gets 30 in leap years.
  static int _tabularDaysInMonth(int year, int month) {
    if (month == 12) {
      return isLeapYear(year) ? 30 : 29;
    }
    return month.isOdd ? 30 : 29;
  }

  /// The single Gregorian → Hijri conversion every consumer routes through.
  ///
  /// [offsetDays] is the user's moon-sighting adjustment
  /// (`AppSettings.hijriOffsetDays`): the Gregorian date is shifted by it
  /// before conversion, so −1 means the local Hijri date is one day behind
  /// the tabular one. Pass it for anything that reflects local observance
  /// (today's date, Ramadan, Eid, recommended fasts, calendar events).
  ///
  /// [shortRamadanYears] is applied after the offset: the offset decides
  /// when Ramadan began, the "Eid announced" override when it ended.
  static HijriDate fromGregorian(DateTime date, {int offsetDays = 0}) {
    final t = _fromJdn(
      _gregorianToJdn(date.year, date.month, date.day) + offsetDays,
    );
    if (!_isShortRamadanMonth(t.year, t.month)) {
      return t;
    }
    if (t.month == ramadanMonth) {
      return t.day < 30 ? t : HijriDate(t.year, shawwalMonth, 1);
    }
    return HijriDate(t.year, shawwalMonth, t.day + 1);
  }

  /// Inverse of [fromGregorian] for the same [offsetDays].
  ///
  /// 30 Ramadan does not exist in a [shortRamadanYears] year: asserts, so a
  /// "last day of Ramadan" helper can't silently land on Eid.
  DateTime toGregorian({int offsetDays = 0}) {
    assert(
      !(month == ramadanMonth &&
          day == 30 &&
          _isShortRamadanMonth(year, month)),
      '30 Ramadan $year does not exist: Ramadan ended after 29 days',
    );
    return _jdnToGregorian(_tabular()._toJdn() - offsetDays);
  }

  /// This observed date in the tabular calendar (undoes the
  /// [shortRamadanYears] shift).
  HijriDate _tabular() {
    if (month != shawwalMonth || !_isShortRamadanMonth(year, month)) {
      return this;
    }
    return day == 1
        ? HijriDate(year, ramadanMonth, 30)
        : HijriDate(year, shawwalMonth, day - 1);
  }

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
      days += _tabularDaysInMonth(priorCycles * 30 + yearInCycle, m);
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
    while (days >= _tabularDaysInMonth(year, month)) {
      days -= _tabularDaysInMonth(year, month);
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
