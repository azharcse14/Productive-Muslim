import '../../../../core/utils/hijri_date.dart';

/// A category of recommended (sunnah / nafl) fast. Each value carries a
/// stable [id] used as the localization-`select` key for both its name
/// (`fastingKindName`) and its virtue/reference note (`fastingKindNote`).
///
/// IMPORTANT — forbidden days are NEVER recommended: the two Eids
/// (1 Shawwal, 10 Dhul-Hijjah) and the days of Tashreeq (11, 12, 13
/// Dhul-Hijjah). [RecommendedFasts.on] excludes them explicitly.
enum FastingKind {
  /// Weekly sunnah — Mondays and Thursdays.
  mondayThursday,

  /// Ayyam al-Beed / the white days: 13, 14, 15 of every hijri month.
  whiteDays,

  /// 9 & 10 Muharram (Tasu'a & Ashura).
  ashura,

  /// 9 Dhul-Hijjah — the Day of Arafah (for non-pilgrims).
  arafah,

  /// The first nine days of Dhul-Hijjah (1–9), the most beloved days.
  dhulHijjah,

  /// Six days of Shawwal (any six after Eid al-Fitr).
  shawwal,
}

/// One recommended fast that applies to a particular Gregorian date.
final class RecommendedFast {
  const RecommendedFast({required this.kind, required this.date});

  final FastingKind kind;

  /// The civil (Gregorian) date this recommendation falls on, normalised to
  /// midnight.
  final DateTime date;

  /// Stable id for the localization `select` keys.
  String get id => kind.name;

  @override
  bool operator ==(Object other) =>
      other is RecommendedFast && other.kind == kind && other.date == date;

  @override
  int get hashCode => Object.hash(kind, date);

  @override
  String toString() => 'RecommendedFast(${kind.name}, $date)';
}

/// A recommended fasting day paired with its hijri context (for screens that
/// want to show "14 Muharram" alongside the reason).
final class UpcomingFast {
  const UpcomingFast({required this.fast, required this.hijri});

  final RecommendedFast fast;
  final HijriDate hijri;
}
