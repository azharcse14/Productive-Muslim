// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Qalbee';

  @override
  String get tabHome => 'Home';

  @override
  String get tabQuran => 'Quran';

  @override
  String get tabMuhasaba => 'Muhasaba';

  @override
  String get tabDua => 'Dua';

  @override
  String get tabMore => 'More';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get galleryTitle => 'Widget Gallery';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get groupCalculation => 'Prayer calculation';

  @override
  String get groupNotifications => 'Notifications';

  @override
  String get groupAppearance => 'Appearance & language';

  @override
  String get groupPrivacy => 'Privacy';

  @override
  String get groupAbout => 'About';

  @override
  String get settingLocation => 'Location';

  @override
  String get settingLocationNotSet => 'Not set';

  @override
  String get settingMadhab => 'Madhab (Asr)';

  @override
  String get settingMethod => 'Calculation method';

  @override
  String get settingAdjustments => 'Minute adjustments';

  @override
  String get settingAdjustmentsSub => 'Fine-tune each prayer ±minutes';

  @override
  String get settingHighLat => 'High-latitude rule';

  @override
  String get settingHighLatSub => 'Advanced — for extreme latitudes';

  @override
  String get settingTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingLanguage => 'Language';

  @override
  String get settingAppLock => 'App lock';

  @override
  String get settingRunSetup => 'Run setup again';

  @override
  String get settingCredits => 'Credits & attributions';

  @override
  String get creditsBody =>
      'Prayer times are computed on-device. City database © GeoNames (CC BY 4.0). Fonts: Schibsted Grotesk, Noto Sans Bengali, IBM Plex Sans Arabic (OFL), KFGQPC Uthmanic Script HAFS © King Fahd Glorious Quran Printing Complex.';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get madhabShafi => 'Shafiʿi';

  @override
  String get madhabExplain => 'Affects Asr time only';

  @override
  String get highLatMiddle => 'Middle of the night';

  @override
  String get highLatSeventh => 'Seventh of the night';

  @override
  String get highLatTwilight => 'Twilight angle';

  @override
  String get methodMuslimWorldLeague => 'Muslim World League';

  @override
  String get methodEgyptian => 'Egyptian General Authority';

  @override
  String get methodKarachi => 'Univ. of Islamic Sciences, Karachi';

  @override
  String get methodUmmAlQura => 'Umm al-Qura (Makkah)';

  @override
  String get methodDubai => 'Dubai';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodMoonsighting => 'Moonsighting Committee';

  @override
  String get methodSingapore => 'Singapore (MUIS)';

  @override
  String get methodNorthAmerica => 'ISNA (North America)';

  @override
  String get methodTurkiye => 'Türkiye (Diyanet)';

  @override
  String get methodTehran => 'Tehran (IGUT)';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get locationTitle => 'Location';

  @override
  String get locationUseGps => 'Use my location';

  @override
  String get locationUseGpsSub =>
      'GPS — works fully offline after the first fix';

  @override
  String get locationChooseCity => 'Choose city manually';

  @override
  String get locationSearchHint => 'Search city…';

  @override
  String get locationPrimingBody =>
      'Qalbee uses your location only to compute prayer times and qibla direction on this device. Nothing ever leaves your phone.';

  @override
  String get locationDeniedFallback =>
      'No problem — pick your city below and everything works the same.';

  @override
  String get locationServiceOff =>
      'Location services are turned off. Pick your city below, or enable location and try again.';

  @override
  String get locationCurrent => 'Current location';

  @override
  String get searchNoResults => 'No matching city — try a different spelling';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String countdownStartsIn(String prayer) {
    return '$prayer starts in';
  }

  @override
  String get countdownJamaatIn => 'Jamaat in';

  @override
  String countdownEndsIn(String prayer) {
    return '$prayer ends in';
  }

  @override
  String get countdownSahriEnds => 'Sahri ends in';

  @override
  String get countdownIftarIn => 'Iftar in';

  @override
  String subAt(String label, String time) {
    return '$label at $time';
  }

  @override
  String get jamaatLabel => 'Jamaat';

  @override
  String get sunriseLabel => 'Sunrise';

  @override
  String get sahriEndsLabel => 'Sahri ends';

  @override
  String get iftarLabel => 'Iftar';

  @override
  String get setJamaat => 'Set jamaat';

  @override
  String get homeSetLocationTitle => 'Where are you?';

  @override
  String get homeSetLocationBody =>
      'Pick your location once and Qalbee computes accurate prayer times for it — fully offline.';

  @override
  String get homeSetLocationCta => 'Set location';

  @override
  String hijriMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Muharram',
      'm2': 'Safar',
      'm3': 'Rabi al-Awwal',
      'm4': 'Rabi al-Thani',
      'm5': 'Jumada al-Ula',
      'm6': 'Jumada al-Akhirah',
      'm7': 'Rajab',
      'm8': 'Shaban',
      'm9': 'Ramadan',
      'm10': 'Shawwal',
      'm11': 'Dhul-Qadah',
      'm12': 'Dhul-Hijjah',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String banglaMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Boishakh',
      'm2': 'Joishtho',
      'm3': 'Asharh',
      'm4': 'Srabon',
      'm5': 'Bhadro',
      'm6': 'Ashwin',
      'm7': 'Kartik',
      'm8': 'Ogrohayon',
      'm9': 'Poush',
      'm10': 'Magh',
      'm11': 'Falgun',
      'm12': 'Choitro',
      'other': '—',
    });
    return '$_temp0';
  }
}
