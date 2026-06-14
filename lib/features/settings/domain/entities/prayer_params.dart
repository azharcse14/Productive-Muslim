/// The five daily prayers.
enum Prayer { fajr, dhuhr, asr, maghrib, isha }

/// Juristic school — "affects Asr time only" (design §4.2).
/// For Asr shadow length Shafiʿi, Maliki and Hanbali share the standard
/// (1× shadow) rule; Hanafi uses 2× shadow.
enum Madhab { hanafi, shafi, maliki, hanbali }

/// Calculation methods exposed in Settings. Mapped to the calculation
/// library inside the data layer (domain stays library-agnostic).
enum CalculationMethodId {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  qatar,
  kuwait,
  moonsightingCommittee,
  singapore,
  northAmerica,
  turkiye,
  tehran,
}

/// Fajr/Isha handling for extreme latitudes (Settings → advanced).
enum HighLatitudeRule { middleOfTheNight, seventhOfTheNight, twilightAngle }

/// Everything prayer computation depends on, flowing through ONE entity
/// (guide §5). Per-prayer minute offsets are user fine-tuning.
final class PrayerParams {
  const PrayerParams({
    this.method = CalculationMethodId.karachi,
    this.madhab = Madhab.hanafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
    this.adjustments = const {},
  });

  final CalculationMethodId method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;

  /// Signed minute offsets per prayer; missing key = 0.
  final Map<Prayer, int> adjustments;

  int adjustmentFor(Prayer prayer) => adjustments[prayer] ?? 0;

  PrayerParams copyWith({
    CalculationMethodId? method,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? adjustments,
  }) {
    return PrayerParams(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      adjustments: adjustments ?? this.adjustments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! PrayerParams ||
        other.method != method ||
        other.madhab != madhab ||
        other.highLatitudeRule != highLatitudeRule ||
        other.adjustments.length != adjustments.length) {
      return false;
    }
    for (final entry in adjustments.entries) {
      if (other.adjustments[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        method,
        madhab,
        highLatitudeRule,
        Object.hashAllUnordered(
          adjustments.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}
