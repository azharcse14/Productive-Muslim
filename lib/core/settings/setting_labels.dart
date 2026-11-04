import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/domain/entities/location_config.dart';
import '../../features/settings/domain/entities/prayer_params.dart';
import '../l10n/gen/app_localizations.dart';

/// The two Asr choices offered in pickers; "Standard" stores [Madhab.shafi]
/// (maliki/hanbali stay valid stored values with the same Asr).
const asrMadhabChoices = [Madhab.hanafi, Madhab.shafi];

/// [m] as one of [asrMadhabChoices].
Madhab asrMadhabOf(Madhab m) => m == Madhab.hanafi ? m : Madhab.shafi;

/// The saved location's name in [l10n]'s language; only `null` is "not
/// set". A GPS fix with no bundled city nearby has an empty name: "Current
/// location". In Bangla a manual city uses its Bangla name, and a raw
/// (geocoded) name has well-known place names translated. Home, the widget,
/// Settings and Onboarding all name the location through this.
String locationLabel(LocationConfig? location, AppLocalizations l10n) {
  if (location == null) {
    return l10n.settingLocationNotSet;
  }
  final bn = l10n.localeName == 'bn';
  if (location case ManualCityLocation(
    :final city,
  ) when bn && (city.nameBn ?? '').isNotEmpty) {
    return city.nameBn!;
  }
  final raw = location.displayName;
  if (raw.isEmpty) {
    return l10n.locationCurrent;
  }
  if (!bn) {
    return raw;
  }
  // Whole words only: "SA" must not hit "USA".
  return raw.replaceAllMapped(
    _bnPlaceName,
    (m) => _bnPlaceNames[m[0]] ?? m[0]!,
  );
}

final _bnPlaceName = RegExp(
  _bnPlaceNames.keys.map((k) => '\\b${RegExp.escape(k)}\\b').join('|'),
);

const _bnPlaceNames = <String, String>{
  'Dhaka': 'ঢাকা',
  'Chittagong': 'চট্টগ্রাম',
  'Chattogram': 'চট্টগ্রাম',
  'Sylhet': 'সিলেট',
  'Rajshahi': 'রাজশাহী',
  'Khulna': 'খুলনা',
  'Barisal': 'বরিশাল',
  'Barishal': 'বরিশাল',
  'Rangpur': 'রংপুর',
  'Mymensingh': 'ময়মনসিংহ',
  'Comilla': 'কুমিল্লা',
  'Cumilla': 'কুমিল্লা',
  'Gazipur': 'গাজীপুর',
  'Narayanganj': 'নারায়ণগঞ্জ',
  'Bogra': 'বগুড়া',
  'Bogura': 'বগুড়া',
  'Pabna': 'পাবনা',
  'Jessore': 'যশোর',
  'Jashore': 'যশোর',
  'Cox\'s Bazar': 'কক্সবাজার',
  'Coxs Bazar': 'কক্সবাজার',
  'Makkah': 'মক্কা',
  'Madinah': 'মদিনা',
  'BD': 'বাংলাদেশ',
  'Bangladesh': 'বাংলাদেশ',
  'SA': 'সৌদি আরব',
};

/// Maps settings enums to localized labels (no hardcoded strings in
/// widgets — guide §6).
extension SettingLabels on AppLocalizations {
  /// Only Hanafi changes Asr, so the other three share one "Standard"
  /// label (see [asrMadhabChoices]).
  String madhabLabel(Madhab m) => switch (m) {
    Madhab.hanafi => madhabHanafi,
    Madhab.shafi || Madhab.maliki || Madhab.hanbali => madhabStandard,
  };

  String methodLabel(CalculationMethodId m) => switch (m) {
    CalculationMethodId.muslimWorldLeague => methodMuslimWorldLeague,
    CalculationMethodId.egyptian => methodEgyptian,
    CalculationMethodId.karachi => methodKarachi,
    CalculationMethodId.ummAlQura => methodUmmAlQura,
    CalculationMethodId.dubai => methodDubai,
    CalculationMethodId.qatar => methodQatar,
    CalculationMethodId.kuwait => methodKuwait,
    CalculationMethodId.moonsightingCommittee => methodMoonsighting,
    CalculationMethodId.singapore => methodSingapore,
    CalculationMethodId.northAmerica => methodNorthAmerica,
    CalculationMethodId.turkiye => methodTurkiye,
    CalculationMethodId.tehran => methodTehran,
  };

  String highLatLabel(HighLatitudeRule r) => switch (r) {
    HighLatitudeRule.middleOfTheNight => highLatMiddle,
    HighLatitudeRule.seventhOfTheNight => highLatSeventh,
    HighLatitudeRule.twilightAngle => highLatTwilight,
  };

  String polarLabel(PolarRule r) => switch (r) {
    PolarRule.nearestLatitude => polarNearest,
    PolarRule.latitude45 => polarLat45,
  };

  String homeCardLabel(HomeCard c) => switch (c) {
    HomeCard.quickActions => homeCardQuickActions,
    HomeCard.specialTimes => specialTimesPageTitle,
    HomeCard.muhasaba => tabMuhasaba,
    HomeCard.continueReading => continueReading,
    HomeCard.tasbih => tasbihTitle,
    HomeCard.reflection => homeCardDaily,
  };

  String themeLabel(AppThemeMode m) => switch (m) {
    AppThemeMode.system => themeSystem,
    AppThemeMode.light => themeLight,
    AppThemeMode.dark => themeDark,
  };

  String prayerLabel(Prayer p) => switch (p) {
    Prayer.fajr => prayerFajr,
    Prayer.dhuhr => prayerDhuhr,
    Prayer.asr => prayerAsr,
    Prayer.maghrib => prayerMaghrib,
    Prayer.isha => prayerIsha,
  };

  /// [prayerLabel], except Dhuhr reads "Jumu'ah" on a Friday [date] when
  /// the user set a Jumu'ah time (others — e.g. women, travellers — pray
  /// Dhuhr as usual).
  String prayerLabelOn(Prayer p, DateTime date, {required bool jumuah}) =>
      jumuah && p == Prayer.dhuhr && date.weekday == DateTime.friday
      ? prayerJumuah
      : prayerLabel(p);
}
