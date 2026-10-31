import '../../../../core/utils/hijri_date.dart';
import '../entities/recommended_fast.dart';

/// Pure recommended-fast math over the in-house tabular [HijriDate] calendar
/// (guide §6: domain logic is static, side-effect free, exhaustively tested).
///
/// Every query takes the user's moon-sighting [offsetDays] (see
/// [HijriDate.fromGregorian]) so the forbidden-day exclusion tracks the
/// locally observed Eid, not the tabular one.
///
/// FORBIDDEN DAYS — fasting is prohibited and is therefore NEVER recommended
/// on the two Eids (1 Shawwal and 10 Dhul-Hijjah) and the three days of
/// Tashreeq (11, 12, 13 Dhul-Hijjah). [on] returns an empty list for these
/// dates even when a weekly Monday/Thursday would otherwise apply. Ramadan
/// days are likewise never offered (the fast is fard, not voluntary).
abstract final class RecommendedFasts {
  /// Hijri months, 1 = Muharram … 12 = Dhul-Hijjah.
  static const _muharram = 1;
  static const _shawwal = 10;
  static const _dhulHijjah = 12;

  /// Days on which fasting is forbidden — checked before anything else.
  static bool isForbidden(HijriDate h) {
    // Eid al-Fitr.
    if (h.month == _shawwal && h.day == 1) {
      return true;
    }
    // Eid al-Adha (10) and the days of Tashreeq (11, 12, 13).
    if (h.month == _dhulHijjah && h.day >= 10 && h.day <= 13) {
      return true;
    }
    return false;
  }

  /// All recommended fasts that apply to the Gregorian civil date [date]
  /// (time-of-day ignored). Empty when [date] is a forbidden day, or simply
  /// an ordinary non-recommended day.
  ///
  /// A single date can carry several reasons (e.g. a white day that also
  /// falls on a Monday) — all are returned, in [FastingKind] order.
  static List<RecommendedFast> on(DateTime date, {int offsetDays = 0}) {
    final day = DateTime(date.year, date.month, date.day);
    final h = HijriDate.fromGregorian(day, offsetDays: offsetDays);
    // Ramadan is obligatory, not nafl — nothing to recommend.
    if (isForbidden(h) || h.month == HijriDate.ramadanMonth) {
      return const [];
    }

    final kinds = <FastingKind>[];

    // Weekly sunnah — Monday (1) and Thursday (4).
    if (day.weekday == DateTime.monday || day.weekday == DateTime.thursday) {
      kinds.add(FastingKind.mondayThursday);
    }

    // Ayyam al-Beed — 13, 14, 15 of every hijri month. (13 Dhul-Hijjah is a
    // day of Tashreeq, already excluded above; the 14th and 15th remain.)
    if (h.day >= 13 && h.day <= 15) {
      kinds.add(FastingKind.whiteDays);
    }

    // Ashura — 9 & 10 Muharram.
    if (h.month == _muharram && (h.day == 9 || h.day == 10)) {
      kinds.add(FastingKind.ashura);
    }

    // First nine days of Dhul-Hijjah (1–9) — and Arafah specifically on the
    // 9th.
    if (h.month == _dhulHijjah && h.day >= 1 && h.day <= 9) {
      kinds.add(h.day == 9 ? FastingKind.arafah : FastingKind.dhulHijjah);
    }

    // Six days of Shawwal — any of 2..30 (the 1st is Eid, excluded). The day
    // count is a personal target; we simply flag every eligible day.
    if (h.month == _shawwal && h.day >= 2) {
      kinds.add(FastingKind.shawwal);
    }

    return [for (final kind in kinds) RecommendedFast(kind: kind, date: day)];
  }

  /// Whether [date] carries at least one recommended fast.
  static bool isRecommended(DateTime date, {int offsetDays = 0}) =>
      on(date, offsetDays: offsetDays).isNotEmpty;

  /// The next [count] Gregorian dates from (and including) [from] that carry
  /// a recommended fast, each paired with its hijri date and first/primary
  /// reason. Scans at most [maxScanDays] ahead (default ~14 months) so the
  /// six-of-Shawwal / Dhul-Hijjah windows are always reachable.
  static List<UpcomingFast> upcoming(
    DateTime from, {
    int count = 7,
    int maxScanDays = 430,
    int offsetDays = 0,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final results = <UpcomingFast>[];
    for (var i = 0; i < maxScanDays && results.length < count; i++) {
      // Calendar-day arithmetic, not Duration: DST days aren't 24h.
      final day = DateTime(start.year, start.month, start.day + i);
      final fasts = on(day, offsetDays: offsetDays);
      if (fasts.isEmpty) {
        continue;
      }
      results.add(
        UpcomingFast(
          fast: fasts.first,
          hijri: HijriDate.fromGregorian(day, offsetDays: offsetDays),
        ),
      );
    }
    return results;
  }
}
