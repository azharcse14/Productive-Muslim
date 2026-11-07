import '../entities/location_config.dart';
import '../entities/prayer_params.dart';

/// ISO country code of [location], read from its "City, CC" display
/// name; '' when unknown (e.g. a GPS fix without a resolved name).
String countryCodeOf(LocationConfig? location) =>
    switch (location?.displayName.split(', ').lastOrNull) {
      final c? when c.length == 2 => c,
      _ => '',
    };

/// Region-suggested calculation method for [countryCode].
CalculationMethodId suggestedMethodFor(String countryCode) =>
    switch (countryCode) {
      'SA' || 'YE' || 'OM' => CalculationMethodId.ummAlQura,
      'AE' => CalculationMethodId.dubai,
      'QA' => CalculationMethodId.qatar,
      'KW' => CalculationMethodId.kuwait,
      'EG' || 'SD' || 'LY' => CalculationMethodId.egyptian,
      'BD' || 'PK' || 'IN' || 'AF' => CalculationMethodId.karachi,
      'SG' || 'MY' || 'ID' => CalculationMethodId.singapore,
      'TR' => CalculationMethodId.turkiye,
      'IR' => CalculationMethodId.tehran,
      'US' || 'CA' => CalculationMethodId.northAmerica,
      'GB' => CalculationMethodId.moonsightingCommittee,
      _ => CalculationMethodId.muslimWorldLeague,
    };

/// Region-default Asr juristic method for [countryCode]: Hanafi where it
/// predominates (South & Central Asia, Türkiye, the Balkans), otherwise
/// the standard (Shafi'i/Maliki/Hanbali) Asr.
Madhab defaultMadhabFor(String countryCode) => switch (countryCode) {
  'BD' || 'PK' || 'IN' || 'AF' || 'TR' => Madhab.hanafi,
  'UZ' || 'TJ' || 'KZ' || 'KG' || 'TM' => Madhab.hanafi,
  'BA' || 'AL' || 'XK' || 'MK' => Madhab.hanafi,
  _ => Madhab.shafi,
};

/// Region-default Hijri offset (days) for [countryCode]: Bangladesh's
/// moon-sighting dates run one day after the tabular reckoning (1 Ramadan
/// 1447 was 19 Feb 2026 there vs 18 Feb tabular). Other regions are
/// unverified, so 0.
int defaultHijriOffsetFor(String countryCode) => switch (countryCode) {
  'BD' => -1,
  _ => 0,
};
