import '../../../../core/utils/hijri_date.dart';

/// Pure Ramadan date math over the in-house tabular [HijriDate] calendar
/// (guide §6: domain logic is static, side-effect free, exhaustively
/// tested).
///
/// Gregorian ↔ Hijri conversions take the user's moon-sighting
/// [offsetDays] (see [HijriDate.fromGregorian]); 0 = pure tabular.
abstract final class RamadanUtils {
  /// Whether [d] falls inside Ramadan.
  static bool isRamadan(HijriDate d) => d.month == HijriDate.ramadanMonth;

  /// The fasting-day number (1..29/30) for [d], or null outside Ramadan.
  static int? rozaDay(HijriDate d) => isRamadan(d) ? d.day : null;

  /// Number of days in Ramadan of [hijriYear] (29 or 30 in the tabular
  /// calendar; always 30 for month 9, but computed, not assumed).
  static int ramadanLength(int hijriYear) =>
      HijriDate.daysInMonth(hijriYear, HijriDate.ramadanMonth);

  /// Gregorian civil date of 1 Ramadan [hijriYear].
  static DateTime firstDayOf(int hijriYear, {int offsetDays = 0}) =>
      HijriDate(hijriYear, HijriDate.ramadanMonth, 1)
          .toGregorian(offsetDays: offsetDays);

  /// Every Gregorian civil date of Ramadan [hijriYear], in order. The
  /// length always equals [ramadanLength].
  static List<DateTime> gregorianDaysOf(int hijriYear, {int offsetDays = 0}) =>
      [
        for (var day = 1; day <= ramadanLength(hijriYear); day++)
          HijriDate(hijriYear, HijriDate.ramadanMonth, day)
              .toGregorian(offsetDays: offsetDays),
      ];

  /// The hijri year of the next (or current) Ramadan relative to [today],
  /// and how many days remain until its first day — 0 when [today] is
  /// already inside that Ramadan.
  static (int year, int daysUntil) nextRamadan(
    DateTime today, {
    int offsetDays = 0,
  }) {
    final date = DateTime(today.year, today.month, today.day);
    final hijri = HijriDate.fromGregorian(date, offsetDays: offsetDays);
    if (hijri.month == HijriDate.ramadanMonth) {
      return (hijri.year, 0);
    }
    final year = hijri.month < HijriDate.ramadanMonth
        ? hijri.year
        : hijri.year + 1;
    // Diff as UTC dates: local midnights straddling a DST change are
    // 23h/25h apart, which makes inDays off by one.
    final first = firstDayOf(year, offsetDays: offsetDays);
    return (
      year,
      DateTime.utc(first.year, first.month, first.day)
          .difference(DateTime.utc(date.year, date.month, date.day))
          .inDays,
    );
  }
}
