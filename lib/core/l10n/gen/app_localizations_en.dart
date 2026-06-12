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

  @override
  String notifAzanTitle(Object prayer, Object time) {
    return '$prayer · $time';
  }

  @override
  String notifAzanBody(Object prayer) {
    return 'It\'s time for $prayer.';
  }

  @override
  String notifJamaatTitle(Object prayer) {
    return '$prayer jamaat soon';
  }

  @override
  String notifJamaatBody(Object time) {
    return 'Jamaat at $time.';
  }

  @override
  String get notifSahriTitle => 'Sahri ends soon';

  @override
  String notifSahriBody(Object time) {
    return 'Sahri ends at $time — finish your meal in time.';
  }

  @override
  String get notifIftarTitle => 'It\'s iftar time';

  @override
  String notifIftarBody(Object time) {
    return 'May Allah accept your fast. Iftar at $time.';
  }

  @override
  String get notifMuhasabaTitle => 'Evening reflection';

  @override
  String get notifMuhasabaBody => 'A quiet minute for today\'s muhasaba?';

  @override
  String get notifMarkPrayed => 'Mark as prayed';

  @override
  String get channelAzan => 'Azan';

  @override
  String get channelReminders => 'Reminders';

  @override
  String get channelSilent => 'Silent prayer alerts';

  @override
  String get notifSettingsTitle => 'Notifications';

  @override
  String get notifPermissionDeniedBanner =>
      'Notifications are off in system settings. Qalbee stays fully useful — enable them to get azan and reminders.';

  @override
  String get notifEnableCta => 'Enable notifications';

  @override
  String get notifExactAlarmBanner =>
      'For azan at the exact minute, allow \"Alarms & reminders\" for Qalbee in system settings.';

  @override
  String get notifExactAlarmCta => 'Allow exact alarms';

  @override
  String get notifBatteryHint =>
      'If reminders arrive late, exclude Qalbee from battery optimization in system settings.';

  @override
  String get notifPerPrayerHeader => 'Prayer alerts';

  @override
  String get azanModeAzan => 'Azan';

  @override
  String get azanModeBeep => 'Beep';

  @override
  String get azanModeSilent => 'Silent';

  @override
  String get azanModeOff => 'Off';

  @override
  String get notifSahriToggle => 'Sahri warning';

  @override
  String get notifSahriToggleSub => 'Before sahri ends';

  @override
  String get notifIftarToggle => 'Iftar alert';

  @override
  String get notifIftarToggleSub => 'At maghrib, with a celebratory tone';

  @override
  String get notifJamaatToggle => 'Jamaat reminder';

  @override
  String get notifJamaatToggleSub => 'Needs jamaat times in My Mosque';

  @override
  String get notifMuhasabaToggle => 'Evening muhasaba nudge';

  @override
  String get notifMuhasabaToggleSub => 'One gentle reminder after Isha';

  @override
  String get leadTimeLabel => 'Lead time';
}
