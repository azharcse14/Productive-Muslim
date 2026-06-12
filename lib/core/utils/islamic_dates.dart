import 'hijri_date.dart';

/// Important days of the Islamic year, shown in the calendar legend.
enum IslamicDay {
  /// 1 Muharram.
  hijriNewYear,

  /// 10 Muharram.
  ashura,

  /// 12 Rabi al-Awwal.
  mawlid,

  /// 27 Rajab.
  israMiraj,

  /// 15 Shaban.
  nisfShaban,

  /// 1 Ramadan.
  ramadanStart,

  /// 27 Ramadan (the most commonly observed night).
  laylatulQadr,

  /// 1 Shawwal.
  eidAlFitr,

  /// 9 Dhul-Hijjah.
  arafah,

  /// 10 Dhul-Hijjah.
  eidAlAdha,
}

/// A fixed hijri-calendar position (month + day) of an [IslamicDay].
final class IslamicDate {
  const IslamicDate(this.day, this.month, this.hijriDay);

  /// Which event this is.
  final IslamicDay day;

  /// Hijri month, 1 = Muharram … 12 = Dhul-Hijjah.
  final int month;

  /// Day within [month].
  final int hijriDay;
}

/// Lookup of important Islamic dates over the tabular [HijriDate] calendar.
///
/// Dates carry the same ±1 day caveat as [HijriDate] itself: actual
/// moon-sighted observances can differ.
abstract final class IslamicDates {
  /// All known events, in calendar order.
  static const List<IslamicDate> all = [
    IslamicDate(IslamicDay.hijriNewYear, 1, 1),
    IslamicDate(IslamicDay.ashura, 1, 10),
    IslamicDate(IslamicDay.mawlid, 3, 12),
    IslamicDate(IslamicDay.israMiraj, 7, 27),
    IslamicDate(IslamicDay.nisfShaban, 8, 15),
    IslamicDate(IslamicDay.ramadanStart, 9, 1),
    IslamicDate(IslamicDay.laylatulQadr, 9, 27),
    IslamicDate(IslamicDay.eidAlFitr, 10, 1),
    IslamicDate(IslamicDay.arafah, 12, 9),
    IslamicDate(IslamicDay.eidAlAdha, 12, 10),
  ];

  /// The event falling on [d], or null when [d] is an ordinary day.
  static IslamicDay? of(HijriDate d) {
    for (final date in all) {
      if (date.month == d.month && date.hijriDay == d.day) {
        return date.day;
      }
    }
    return null;
  }

  /// All events whose Gregorian civil date falls inside the given Gregorian
  /// [year]/[month], paired with that date, in chronological order.
  ///
  /// Implemented by walking every day of the month: a Gregorian month can
  /// span two hijri months (and, around Muharram, two hijri years), so a
  /// simple per-hijri-month conversion would miss events.
  static List<(IslamicDay, DateTime)> inGregorianMonth(int year, int month) {
    final results = <(IslamicDay, DateTime)>[];
    // Day 0 of the next month = last day of this month.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final event = of(HijriDate.fromGregorian(date));
      if (event != null) {
        results.add((event, date));
      }
    }
    return results;
  }
}
