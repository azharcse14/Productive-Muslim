import '../../../../core/utils/hijri_date.dart';

/// A years / months / days decomposition of an elapsed span. Always
/// non-negative; a zero span (birth == reference date) is all zeros.
final class AgeBreakdown {
  const AgeBreakdown({
    required this.years,
    required this.months,
    required this.days,
  });

  final int years;
  final int months;
  final int days;
}

/// Outcome of [AgeCalculator.calculate]: the same elapsed span expressed in
/// both the Gregorian and the Hijri (Islamic) calendar, plus the raw whole
/// day count (calendar-agnostic).
final class AgeResult {
  const AgeResult({
    required this.gregorian,
    required this.hijri,
    required this.totalDays,
  });

  /// Age in the Gregorian (Western) calendar.
  final AgeBreakdown gregorian;

  /// Age in the Hijri (tabular Islamic) calendar — derived via
  /// [HijriDate.fromGregorian]. Because Hijri years are ~11 days shorter,
  /// the year count runs slightly ahead of the Gregorian one.
  final AgeBreakdown hijri;

  /// Whole calendar days between the two dates (date-only), the same in any
  /// calendar. Clamped to 0 when the reference date precedes the birth date.
  final int totalDays;
}

/// Pure age math (guide §6: static, side-effect free, exhaustively tested).
///
/// The same borrow algorithm runs over two calendars. Given a start date
/// (y0/m0/d0) and an end date (y1/m1/d1) in some calendar:
///
///   1. Take the naive component differences y1-y0, m1-m0, d1-d0.
///   2. If days < 0, borrow one month: add the length of the month that
///      *precedes* the end month (in that calendar, for the relevant year),
///      and decrement months.
///   3. If months < 0, borrow one year: add 12 and decrement years.
///
/// Borrowing the *preceding* month's length is the standard convention —
/// e.g. born 31 Jan, asked on 1 Mar (non-leap): the day shortfall is filled
/// by February's 28 days, giving 1 month 1 day, not 1 month + (31-day fill).
abstract final class AgeCalculator {
  /// Computes the age between [birthDate] and [onDate].
  ///
  /// Only the date part of each argument matters (time-of-day is ignored).
  /// If [onDate] is before [birthDate] every field is clamped to 0.
  static AgeResult calculate({
    required DateTime birthDate,
    required DateTime onDate,
  }) {
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final on = DateTime(onDate.year, onDate.month, onDate.day);

    // Reference date before birth (or equal) → nothing has elapsed.
    if (!on.isAfter(birth)) {
      const zero = AgeBreakdown(years: 0, months: 0, days: 0);
      return const AgeResult(
        gregorian: zero,
        hijri: zero,
        totalDays: 0,
      );
    }

    final totalDays = on.difference(birth).inDays;

    final gregorian = _diff(
      startYear: birth.year,
      startMonth: birth.month,
      startDay: birth.day,
      endYear: on.year,
      endMonth: on.month,
      endDay: on.day,
      daysInPrecedingMonth: _gregorianDaysInPrecedingMonth,
    );

    final birthHijri = HijriDate.fromGregorian(birth);
    final onHijri = HijriDate.fromGregorian(on);
    final hijri = _diff(
      startYear: birthHijri.year,
      startMonth: birthHijri.month,
      startDay: birthHijri.day,
      endYear: onHijri.year,
      endMonth: onHijri.month,
      endDay: onHijri.day,
      daysInPrecedingMonth: HijriDate.daysInMonth,
    );

    return AgeResult(
      gregorian: gregorian,
      hijri: hijri,
      totalDays: totalDays,
    );
  }

  /// Generic borrow algorithm shared by both calendars. [daysInPrecedingMonth]
  /// returns the length of the end-date's *previous* month, taking calendar
  /// and year into account (passed (year, month) of the end date).
  static AgeBreakdown _diff({
    required int startYear,
    required int startMonth,
    required int startDay,
    required int endYear,
    required int endMonth,
    required int endDay,
    required int Function(int year, int month) daysInPrecedingMonth,
  }) {
    var years = endYear - startYear;
    var months = endMonth - startMonth;
    var days = endDay - startDay;

    if (days < 0) {
      // Borrow the month preceding the end month. Months wrap 12 → 1 with
      // year - 1 (matters for Hijri month 12, whose length is year-dependent).
      var prevMonth = endMonth - 1;
      var prevYear = endYear;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear -= 1;
      }
      days += daysInPrecedingMonth(prevYear, prevMonth);
      months -= 1;
    }

    if (months < 0) {
      months += 12;
      years -= 1;
    }

    return AgeBreakdown(years: years, months: months, days: days);
  }

  /// Gregorian month length including leap-year February.
  static int _gregorianDaysInPrecedingMonth(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isGregorianLeapYear(year)) {
      return 29;
    }
    return lengths[month - 1];
  }

  static bool _isGregorianLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}
