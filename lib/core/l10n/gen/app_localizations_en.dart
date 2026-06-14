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
  String get madhabMaliki => 'Maliki';

  @override
  String get madhabHanbali => 'Hanbali';

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
  String get sunsetLabel => 'Sunset';

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

  @override
  String get myMosqueTitle => 'My Mosque';

  @override
  String get myMosqueSubtitle => 'Jamaat times for your mosque';

  @override
  String get addProfile => 'Add profile';

  @override
  String get profileNameHint => 'Mosque name (e.g. Home, Work)';

  @override
  String get defaultProfileName => 'My Mosque';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String deleteProfileConfirm(String name) {
    return 'Delete \"$name\"? Its jamaat times will be removed.';
  }

  @override
  String get jamaatModeNone => 'None';

  @override
  String get jamaatModeOffset => 'Offset';

  @override
  String get jamaatModeFixed => 'Fixed';

  @override
  String offsetAfterStart(int count) {
    return '$count min after waqt starts';
  }

  @override
  String fixedAtTime(String time) {
    return 'Jamaat at $time';
  }

  @override
  String get pickTime => 'Pick time';

  @override
  String get jamaatReminderHint =>
      'Jamaat reminders are configured under Notifications.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaAligned => 'Facing the Qibla';

  @override
  String qiblaHeading(String degrees, String cardinal) {
    return '$degrees° $cardinal';
  }

  @override
  String qiblaDistance(String km) {
    return '$km km to the Kaaba';
  }

  @override
  String get qiblaCalibrate =>
      'Move your phone in a figure-8 to calibrate the compass';

  @override
  String get qiblaSensorUnavailable =>
      'Compass sensor unavailable on this device';

  @override
  String qiblaVerbalBearing(String degrees, String cardinal) {
    return 'Qibla is at $degrees° $cardinal from north';
  }

  @override
  String get qiblaNeedsLocation =>
      'Set your location to find the qibla direction';

  @override
  String get muhasabaTitle => 'Muhasaba';

  @override
  String get muhasabaFirstDayTitle => 'Your daily muhasaba';

  @override
  String get muhasabaFirstDayBody =>
      'Muhasaba is gentle self-accounting: small daily deeds, tracked kindly. Check off what you did — every bit counts.';

  @override
  String get muhasabaStart => 'Bismillah, let\'s begin';

  @override
  String trackerName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'salah_fajr': 'Fajr prayer',
      'salah_dhuhr': 'Dhuhr prayer',
      'salah_asr': 'Asr prayer',
      'salah_maghrib': 'Maghrib prayer',
      'salah_isha': 'Isha prayer',
      'quran': 'Quran reading',
      'azkar': 'Azkar',
      'sadaqah': 'Sadaqah',
      'tahajjud': 'Tahajjud',
      'roza': 'Fasting',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String get addTracker => 'Add item';

  @override
  String get editTracker => 'Edit item';

  @override
  String get trackerNameHint => 'Name (e.g. Morning adhkar)';

  @override
  String get trackerKindLabel => 'Type';

  @override
  String get kindYesNo => 'Yes / No';

  @override
  String get kindCount => 'Count';

  @override
  String get kindDuration => 'Duration';

  @override
  String get targetLabel => 'Daily target (optional)';

  @override
  String get targetCountSuffix => 'times';

  @override
  String get targetMinutesSuffix => 'minutes';

  @override
  String get archiveTracker => 'Archive';

  @override
  String get unarchiveTracker => 'Restore';

  @override
  String get archiveExplain =>
      'Archived items disappear from your daily list, but every past entry is preserved.';

  @override
  String get archivedSection => 'Archived';

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get todayTab => 'Today';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get overallCompletion => 'Overall completion';

  @override
  String currentStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String bestStreakLabel(int count) {
    return 'Best: $count';
  }

  @override
  String get salahLockedToast => 'This prayer\'s time hasn\'t started yet';

  @override
  String muhasabaDoneCount(int done, int total) {
    return '$done/$total done';
  }

  @override
  String vsPrevious(String trend) {
    String _temp0 = intl.Intl.selectLogic(trend, {
      'up': 'Better than the last period',
      'same': 'Steady as the last period',
      'down': 'A fresh start — keep going',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String get emptyRange => 'No entries in this range yet';

  @override
  String minutesValue(int count) {
    return '$count min';
  }

  @override
  String get notYet => 'Not yet';

  @override
  String get quranTitle => 'Quran';

  @override
  String get searchSurahHint => 'Search surah…';

  @override
  String get continueReading => 'Continue reading';

  @override
  String surahMeta(int count, String place) {
    return '$count ayahs · $place';
  }

  @override
  String revelationName(String place) {
    String _temp0 = intl.Intl.selectLogic(place, {
      'meccan': 'Meccan',
      'medinan': 'Medinan',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String get readerFontSize => 'Arabic text size';

  @override
  String get showTranslation => 'Show translation';

  @override
  String get ayahCopied => 'Ayah copied';

  @override
  String get bookmarkLabel => 'Bookmark';

  @override
  String get quranFirstOpen =>
      'Bismillah — start reading and Qalbee will remember where you left off.';

  @override
  String ayahShareSuffix(int surah, int ayah) {
    return '— Quran $surah:$ayah';
  }

  @override
  String get duaTitle => 'Dua & Tasbih';

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String get asmaulHusnaTitle => 'Asmaul Husna';

  @override
  String duaCategoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'morning_evening': 'Morning & evening',
      'sleep': 'Sleep',
      'waking': 'Waking up',
      'food': 'Food & drink',
      'home': 'Entering & leaving home',
      'travel': 'Travel',
      'salah': 'Salah',
      'distress': 'Distress & relief',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String duaCount(int count) {
    return '$count duas';
  }

  @override
  String repeatTimes(int count) {
    return 'Repeat $count×';
  }

  @override
  String get referenceLabel => 'Reference';

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihCustom => 'Custom';

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihResetConfirm => 'Save this round to history and reset?';

  @override
  String tasbihSessionLine(int count) {
    return 'Today: $count counted';
  }

  @override
  String get tasbihTargetReached => 'Target reached — may Allah accept';

  @override
  String get ramadanTitle => 'Ramadan';

  @override
  String rozaDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String daysUntilRamadan(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days until Ramadan',
      one: '1 day until Ramadan',
    );
    return '$_temp0';
  }

  @override
  String get monthTable => 'Sahri & iftar this month';

  @override
  String get zakatTitle => 'Zakat calculator';

  @override
  String get zakatCash => 'Cash on hand';

  @override
  String get zakatBank => 'Bank balance';

  @override
  String get zakatGold => 'Gold (grams)';

  @override
  String get zakatSilver => 'Silver (grams)';

  @override
  String get zakatBusiness => 'Business assets';

  @override
  String get zakatInvestments => 'Investments';

  @override
  String get zakatOwed => 'Money owed to you';

  @override
  String get zakatDebts => 'Debts (deducted)';

  @override
  String get zakatGoldPrice => 'Gold price per gram';

  @override
  String get zakatSilverPrice => 'Silver price per gram';

  @override
  String get zakatCalculate => 'Calculate';

  @override
  String zakatNisab(String amount) {
    return 'Nisab threshold: $amount';
  }

  @override
  String zakatDue(String amount) {
    return 'Zakat due: $amount';
  }

  @override
  String get zakatNotPayable =>
      'Your zakatable wealth is below the nisab — no zakat is due.';

  @override
  String get fitraInfo =>
      'Sadaqat al-fitr is due per person before Eid prayer — roughly one sa\' (~2.5–3 kg) of staple food, or its value, per family member.';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String islamicDayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'hijriNewYear': 'Hijri New Year',
      'ashura': 'Ashura',
      'mawlid': 'Mawlid',
      'israMiraj': 'Isra & Miraj',
      'nisfShaban': 'Mid-Shaban',
      'ramadanStart': 'Ramadan begins',
      'laylatulQadr': 'Laylatul Qadr',
      'eidAlFitr': 'Eid al-Fitr',
      'arafah': 'Day of Arafah',
      'eidAlAdha': 'Eid al-Adha',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String get onboardingWelcomeTitle =>
      'A companion for the heart\'s daily deen';

  @override
  String get onboardingWelcomeBody =>
      'Prayer times, qibla, Quran, dua, and gentle self-accounting — all offline, all yours.';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLocationTitle => 'Where are you?';

  @override
  String get onboardingMadhabTitle => 'Asr calculation';

  @override
  String get onboardingMadhabNote =>
      'This affects Asr time only — you can change it anytime in Settings.';

  @override
  String get onboardingMethodTitle => 'Calculation method';

  @override
  String get onboardingMethodNote =>
      'Suggested for your region. You can change this later in Settings.';

  @override
  String get onboardingNotifTitle => 'Stay gently reminded';

  @override
  String get onboardingNotifBody =>
      'Azan at each waqt, sahri & iftar alerts, and an evening muhasaba nudge — all computed on your device.';

  @override
  String get onboardingNotifAllow => 'Allow notifications';

  @override
  String get onboardingNotifSkip => 'Maybe later';

  @override
  String get onboardingFinishTitle => 'Bismillah';

  @override
  String get onboardingFinishBody =>
      'Everything is ready. May your days be filled with light.';

  @override
  String get onboardingBegin => 'Begin';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get appLockEnterPin => 'Enter your PIN';

  @override
  String get appLockSetPin => 'Set a 4-digit PIN';

  @override
  String get appLockConfirmPin => 'Confirm your PIN';

  @override
  String get appLockPinMismatch => 'PINs didn\'t match — try again';

  @override
  String get appLockWrongPin => 'Wrong PIN — try again';

  @override
  String get appLockUseBiometric => 'Use fingerprint / face';

  @override
  String get appLockEnable => 'App lock';

  @override
  String get appLockEnableSub =>
      'Require a PIN (and biometrics) to open Qalbee';

  @override
  String get appLockDisable => 'Turn off app lock';
}
