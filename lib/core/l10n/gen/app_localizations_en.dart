// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Productive Muslim';

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
  String get moreGroupWorship => 'Worship';

  @override
  String get moreGroupTools => 'Tools';

  @override
  String get moreGroupYou => 'You';

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
  String get settingHijriOffset => 'Hijri date adjustment';

  @override
  String get settingHijriOffsetSub => 'Match your local moon-sighting';

  @override
  String hijriOffsetValue(int count, String sign) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sign$countString days',
      one: '${sign}1 day',
    );
    return '$_temp0';
  }

  @override
  String get settingSahriSafety => 'Sahri safety margin';

  @override
  String get settingSahriSafetySub => 'End sahri this many minutes before Fajr';

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
  String get settingShowAchievements => 'Show achievements';

  @override
  String get settingShowAchievementsSub =>
      'Badges and streak milestones in Muhasaba';

  @override
  String get settingHaptics => 'Haptic feedback';

  @override
  String get settingHapticsSub => 'Vibrate on taps and tasbih counts';

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
  String get openSystemSettings => 'Open settings';

  @override
  String get locationSearchError =>
      'Couldn\'t search cities. Please try again.';

  @override
  String get locationSearchHint => 'Search city…';

  @override
  String get locationPrimingBody =>
      'Productive Muslim uses your location on this device to calculate prayer times and the qibla direction. It is shared only if you choose to open nearby mosques in Maps.';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString min';
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
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Peaceful night';

  @override
  String continueReadingAyah(String number) {
    return 'Ayah $number';
  }

  @override
  String get forbiddenTimesTitle => 'Forbidden times';

  @override
  String get naflTimesTitle => 'Nafl times';

  @override
  String get specialNow => 'Now';

  @override
  String get specialTimeForbiddenSunrise => 'After sunrise';

  @override
  String get specialTimeForbiddenZawal => 'Midday (zawal)';

  @override
  String get specialTimeForbiddenSunset => 'Before sunset';

  @override
  String get specialTimeIshraq => 'Ishraq';

  @override
  String get specialTimeDuha => 'Duha (Chasht)';

  @override
  String get specialTimeSalatZawal => 'Salat al-Zawal';

  @override
  String get specialTimeAwwabin => 'Awwabin';

  @override
  String get specialTimeTahajjud => 'Tahajjud';

  @override
  String get forbiddenTimesSubtitle =>
      'No salah may be offered in these three moments.';

  @override
  String get naflTimesSubtitle => 'Best times for voluntary (nafl) prayers.';

  @override
  String get specialTimesLearnMore => 'Tap for details';

  @override
  String get specialTimesPageTitle => 'Forbidden & nafl times';

  @override
  String get forbiddenTimesIntro =>
      'There are three moments in the day when offering any salah is prohibited (makruh tahrimi). The Prophet ﷺ forbade praying as the sun rises, at its zenith, and as it sets — the times the disbelievers worshipped the sun. Missed obligatory prayers remembered in these windows may still be made up.';

  @override
  String get naflTimesIntro =>
      'Beyond the obligatory prayers, these are recommended voluntary (nafl) prayers with their preferred times — a means of drawing nearer to Allah and making up for shortcomings in the fard.';

  @override
  String get specialDetailForbiddenSunrise =>
      'From sunrise until the sun has fully risen above the horizon (about 15 minutes). The Prophet ﷺ said the sun rises between the two horns of Shaytan, so salah is withheld until it clears.';

  @override
  String get specialDetailForbiddenZawal =>
      'The brief moment the sun stands at its highest point (istiwa) before passing the meridian into the Dhuhr time. No salah is offered until it begins to decline.';

  @override
  String get specialDetailForbiddenSunset =>
      'From when the sun yellows and starts to set until it has fully set (Maghrib). As at sunrise, salah is withheld while the sun sets.';

  @override
  String get specialDetailIshraq =>
      'Two rak\'ahs offered shortly after the sun has fully risen. Whoever prays Fajr in congregation, sits in dhikr until sunrise, then prays two rak\'ahs earns the reward of a complete Hajj and Umrah.';

  @override
  String get specialDetailDuha =>
      'The forenoon prayer of two to twelve rak\'ahs, best offered once the sun has risen high, lasting until just before zawal. A charity is due for every joint of the body each morning, and these rak\'ahs suffice for it.';

  @override
  String get specialDetailSalatZawal =>
      'Offered right after the sun passes its zenith and begins to decline, just before the Dhuhr fard. The Prophet ﷺ used to pray when the gates of heaven are opened at this hour.';

  @override
  String get specialDetailAwwabin =>
      'Voluntary rak\'ahs offered between the Maghrib and Isha prayers — the salah of the oft-returning (awwabin), beloved for turning back to Allah after the day\'s work.';

  @override
  String get specialDetailTahajjud =>
      'Night prayer in the last third of the night, the most virtuous voluntary salah. It is the hour Allah descends to the lowest heaven, answering the one who calls upon Him.';

  @override
  String get setJamaat => 'Set jamaat time';

  @override
  String get switchMosqueTitle => 'Jamaat mosque';

  @override
  String get mosqueAutoBadge => 'Auto';

  @override
  String get mosqueOverrideBadge => 'Override';

  @override
  String get mosqueAutoSubtitle => 'Switching automatically by your schedule';

  @override
  String get mosqueOverrideSubtitle =>
      'Temporary override — reset to resume the schedule';

  @override
  String get mosqueResetToSchedule => 'Reset to schedule';

  @override
  String get mosqueManage => 'Manage mosques & schedule';

  @override
  String get scheduleSectionTitle => 'Auto-switch';

  @override
  String get scheduleModeManual => 'Manual';

  @override
  String get scheduleModeAuto => 'Auto';

  @override
  String get scheduleAutoHint =>
      'Productive Muslim picks the mosque by day and time.';

  @override
  String get scheduleRulesTitle => 'Rules';

  @override
  String get scheduleRulesEmpty =>
      'No rules yet. Add one to switch automatically.';

  @override
  String get scheduleAddRule => 'Add rule';

  @override
  String get scheduleDefaultMosque => 'Default mosque';

  @override
  String get scheduleDefaultHint => 'Used when no rule matches.';

  @override
  String get scheduleAllDay => 'All day';

  @override
  String get scheduleEveryDay => 'Every day';

  @override
  String get scheduleFrom => 'From';

  @override
  String get scheduleTo => 'To';

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      '7': 'Sun',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get homeSetLocationTitle => 'Where are you?';

  @override
  String get homeSetLocationBody =>
      'Pick your location once and Productive Muslim computes accurate prayer times for it — fully offline.';

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
  String get notifKeepAliveTitle => 'Keep reminders running';

  @override
  String get notifKeepAliveBody =>
      'Open Productive Muslim when you have a moment, so your prayer reminders continue.';

  @override
  String notifScheduledUntil(String when) {
    return 'Reminders scheduled until $when';
  }

  @override
  String get notifScheduledNone => 'No reminders are scheduled right now.';

  @override
  String get notifMarkPrayed => 'Mark as prayed';

  @override
  String get channelAzan => 'Azan';

  @override
  String get channelReminders => 'Reminders';

  @override
  String get channelSilent => 'Silent prayer alerts';

  @override
  String get channelBeep => 'Prayer alerts (beep)';

  @override
  String get notifSettingsTitle => 'Notifications';

  @override
  String get notifPermissionDeniedBanner =>
      'Notifications are off in system settings. Productive Muslim stays fully useful — enable them to get azan and reminders.';

  @override
  String get notifEnableCta => 'Enable notifications';

  @override
  String get notifExactAlarmBanner =>
      'For azan at the exact minute, allow \"Alarms & reminders\" for Productive Muslim in system settings.';

  @override
  String get notifExactAlarmCta => 'Allow exact alarms';

  @override
  String get notifBatteryHint =>
      'If reminders arrive late, exclude Productive Muslim from battery optimization in system settings.';

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
  String get notifDailyToggle => 'Daily reminder';

  @override
  String get notifDailyToggleSub => 'A hadith or dua of the day, at your time';

  @override
  String get notifDailyKindHadith => 'Hadith';

  @override
  String get notifDailyKindDua => 'Dua';

  @override
  String get notifDailyTimeLabel => 'Reminder time';

  @override
  String get notifDailyHadithTitle => 'Hadith of the day';

  @override
  String get notifDailyHadithBody =>
      'Today\'s hadith is ready — tap to read it.';

  @override
  String get notifDailyDuaTitle => 'Dua of the day';

  @override
  String get notifDailyDuaBody => 'Today\'s dua is ready — tap to read it.';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString min after waqt starts';
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
  String get qiblaFinding => 'Finding direction…';

  @override
  String get qiblaNeedsLocation =>
      'Set your location to find the qibla direction';

  @override
  String get muhasabaTitle => 'Muhasaba';

  @override
  String get muhasabaFirstDayTitle => 'Your daily muhasaba';

  @override
  String get muhasabaDayComplete => 'Every deed done today — alhamdulillah';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String bestStreakLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Best: $countString';
  }

  @override
  String get salahLockedToast => 'This prayer\'s time hasn\'t started yet';

  @override
  String a11yMarkPrayed(String prayer) {
    return 'Mark $prayer as prayed';
  }

  @override
  String a11yPrayerLocked(String prayer) {
    return '$prayer: its time hasn\'t started yet';
  }

  @override
  String muhasabaDoneCount(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString/$totalString done';
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString min';
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ayahs · $place';
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
  String get readerSettings => 'Reading settings';

  @override
  String get copyAyah => 'Copy ayah';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get quranLoadError =>
      'Couldn\'t open the Quran text. Please try again.';

  @override
  String get copyLabel => 'Copy';

  @override
  String get copiedLabel => 'Copied';

  @override
  String get ayahCopied => 'Ayah copied';

  @override
  String get bookmarksTitle => 'Bookmarks';

  @override
  String get bookmarksEmpty =>
      'No bookmarks yet. Tap the bookmark icon on any ayah to save it here.';

  @override
  String get bookmarkLabel => 'Bookmark';

  @override
  String get quranFirstOpen =>
      'Bismillah — start reading and Productive Muslim will remember where you left off.';

  @override
  String ayahShareSuffix(int surah, int ayah) {
    final intl.NumberFormat surahNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String surahString = surahNumberFormat.format(surah);
    final intl.NumberFormat ayahNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ayahString = ayahNumberFormat.format(ayah);

    return '— Quran $surahString:$ayahString';
  }

  @override
  String get duaTitle => 'Dua & Tasbih';

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String get asmaulHusnaTitle => 'Asmaul Husna';

  @override
  String get asmaQuizTitle => 'Names quiz';

  @override
  String get asmaLoadError =>
      'Couldn\'t load the names. Please try again later.';

  @override
  String get asmaQuizModeNameToMeaning => 'Name → meaning';

  @override
  String get asmaQuizModeMeaningToName => 'Meaning → name';

  @override
  String get asmaQuizPromptMeaning => 'What is the meaning of this name?';

  @override
  String get asmaQuizPromptName => 'Which name has this meaning?';

  @override
  String asmaQuizProgress(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$currentString of $totalString';
  }

  @override
  String get asmaQuizNext => 'Next';

  @override
  String get asmaQuizSeeResult => 'See result';

  @override
  String get asmaQuizResultTitle => 'Quiz complete';

  @override
  String get asmaQuizResultEncouragement =>
      'Every name you revisit draws you closer. There\'s no pass or fail here — return whenever you like and try again.';

  @override
  String asmaQuizScore(int score, int total) {
    final intl.NumberFormat scoreNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String scoreString = scoreNumberFormat.format(score);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$scoreString/$totalString';
  }

  @override
  String asmaQuizBest(int best) {
    final intl.NumberFormat bestNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bestString = bestNumberFormat.format(best);

    return 'Best score: $bestString';
  }

  @override
  String get asmaQuizPlayAgain => 'Try again';

  @override
  String get fastingTitle => 'Sunnah fasting';

  @override
  String get fastingSubtitle => 'Recommended days & your log';

  @override
  String get fastingTodayRecommended => 'Recommended fast today';

  @override
  String get fastingTodayNone => 'No recommended fast today';

  @override
  String get fastingTodayNoneNote =>
      'There is no specific sunnah fast today, but a voluntary fast is always rewarded.';

  @override
  String get fastingTodayForbidden => 'Fasting is not permitted today';

  @override
  String get fastingTodayForbiddenNote =>
      'Fasting is forbidden on the two Eids and the days of Tashreeq (11–13 Dhul-Hijjah).';

  @override
  String get fastingTodayRamadan => 'Ramadan — the obligatory fast';

  @override
  String get fastingTodayRamadanNote =>
      'Today is a day of Ramadan, an obligatory fast. May Allah accept it.';

  @override
  String get fastingLogToday => 'Log today';

  @override
  String get fastingLogVoluntary => 'Log a voluntary fast';

  @override
  String get fastingLoggedToday => 'Logged for today';

  @override
  String get fastingLogTitle => 'Your fasting log';

  @override
  String get fastingTotal => 'Total';

  @override
  String get fastingThisMonth => 'This month';

  @override
  String get fastingThisHijriMonth => 'This hijri month';

  @override
  String get fastingFasted => 'Fasted';

  @override
  String fastingHeatmapLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fasts logged this month',
      one: '1 fast logged this month',
      zero: 'No fasts logged this month',
    );
    return '$_temp0';
  }

  @override
  String get fastingUpcomingTitle => 'Upcoming recommended fasts';

  @override
  String fastingKindName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'mondayThursday': 'Monday & Thursday',
      'whiteDays': 'White days (Ayyam al-Beed)',
      'ashura': 'Ashura',
      'arafah': 'Day of Arafah',
      'dhulHijjah': 'First ten days of Dhul-Hijjah',
      'shawwal': 'Six days of Shawwal',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String fastingKindNote(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'mondayThursday':
          'Deeds are presented to Allah on Mondays and Thursdays, and the Prophet ﷺ loved to be fasting then. (Tirmidhi)',
      'whiteDays':
          'Fasting the 13th, 14th and 15th of each hijri month is like fasting the whole year. (Nasa\'i)',
      'ashura':
          'Fasting Ashura expiates the sins of the past year; fast the 9th with it. (Muslim)',
      'arafah':
          'Fasting the Day of Arafah expiates the past and the coming year. (Muslim)',
      'dhulHijjah':
          'No good deeds are more beloved to Allah than those done in these ten days. (Bukhari)',
      'shawwal':
          'Fasting Ramadan then six days of Shawwal is like fasting the entire year. (Muslim)',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementsSubtitle => 'Every small step counts — keep going.';

  @override
  String achievementHow(String kind, String count) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'streak': 'Log at least one deed in Muhasaba $count days in a row.',
      'salah': 'Check off a salah on $count different days.',
      'dhikr': 'Count and save $count dhikr with the tasbih.',
      'quranStart': 'Open the Quran and start reading.',
      'quran': 'Complete your Quran reading on $count days.',
      'bookmark': 'Bookmark $count ayahs.',
      'fast': 'Log $count fasts.',
      'other': 'Keep going.',
    });
    return '$_temp0';
  }

  @override
  String get achievementUnlocked => 'Unlocked';

  @override
  String achievementsCount(int unlocked, int total) {
    final intl.NumberFormat unlockedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String unlockedString = unlockedNumberFormat.format(unlocked);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$unlockedString of $totalString earned';
  }

  @override
  String achievementCategory(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'streaks': 'Streaks',
      'salah': 'Salah',
      'dhikr': 'Dhikr',
      'quran': 'Quran',
      'fasting': 'Fasting',
      'other': 'Achievements',
    });
    return '$_temp0';
  }

  @override
  String achievementName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'streak_3': 'Three in a row',
      'streak_7': 'A steady week',
      'streak_30': 'A month of devotion',
      'streak_100': 'A hundred days',
      'salah_10': 'Ten days of salah',
      'salah_50': 'Fifty days of salah',
      'salah_200': 'Two hundred days of salah',
      'dhikr_100': 'First hundred dhikr',
      'dhikr_1000': 'A thousand dhikr',
      'dhikr_10000': 'Ten thousand dhikr',
      'quran_start': 'Opened the Quran',
      'quran_days_7': 'A week with the Quran',
      'quran_days_30': 'A month with the Quran',
      'quran_bookmark_5': 'Five bookmarks',
      'fast_1': 'First fast',
      'fast_10': 'Ten fasts',
      'fast_30': 'Thirty fasts',
      'other': 'Achievement',
    });
    return '$_temp0';
  }

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
      'wudu': 'Wudu',
      'clothes': 'Dressing',
      'weather': 'Rain & weather',
      'istighfar': 'Seeking forgiveness',
      'gratitude': 'Gratitude',
      'protection': 'Protection',
      'sneezing': 'Sneezing',
      'marketplace': 'Marketplace',
      'adhan': 'Adhan & iqamah',
      'toilet': 'Toilet',
      'knowledge': 'Knowledge & guidance',
      'family': 'Family & marriage',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String duaCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString duas';
  }

  @override
  String repeatTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Repeat $countString×';
  }

  @override
  String get referenceLabel => 'Reference';

  @override
  String get ruqyahTitle => 'Ruqyah';

  @override
  String get ruqyahSubtitle => 'Qur\'anic protection & healing';

  @override
  String get ruqyahHowToTitle => 'How to perform ruqyah';

  @override
  String get ruqyahHowToBody =>
      'Recite these verses and supplications sincerely, with full trust that healing is from Allah alone. Blow lightly over yourself or the one being treated, or over water to drink. Ruqyah is from the Qur\'an and authentic Sunnah only — never seek out amulets or sorcerers.';

  @override
  String ruqyahCategoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'protection': 'Protection',
      'three_quls': 'The three Quls',
      'healing': 'Healing & sickness',
      'evil_eye': 'Evil eye & envy',
      'sihr_jinn': 'Sihr, jinn & whispers',
      'anxiety_grief': 'Anxiety, grief & distress',
      'sleep': 'Sleep & nightmares',
      'morning_evening': 'Morning & evening',
      'enemies': 'Enemies & oppressors',
      'children': 'Protecting children',
      'fitan': 'Trials & the Dajjal',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String ruqyahCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString passages';
  }

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihCustom => 'Custom';

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihDiscard => 'Discard';

  @override
  String get tasbihUndo => 'Undo last count';

  @override
  String get tasbihResetConfirm => 'Save this round to history and reset?';

  @override
  String tasbihSessionLine(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Today: $countString counted';
  }

  @override
  String get tasbihTargetReached => 'Target reached — may Allah accept';

  @override
  String get ramadanTitle => 'Ramadan';

  @override
  String rozaDayOf(int day, int total) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Day $dayString of $totalString';
  }

  @override
  String daysUntilRamadan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days until Ramadan',
      one: '1 day until Ramadan',
    );
    return '$_temp0';
  }

  @override
  String get monthTable => 'Sahri & iftar this month';

  @override
  String get zakatTitle => 'Zakat calculator';

  @override
  String get zakatSubtitle => 'Work out the zakat due on your wealth';

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
  String get zakatNeedPrice =>
      'Enter today\'s gold or silver price to work out the nisab.';

  @override
  String get zakatInvalidNumber => 'Enter a valid number';

  @override
  String get zakatNeedMetalPrice =>
      'Enter the price for each metal you entered grams of.';

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
  String get onboardingNotifDenied =>
      'Notifications are off. You can turn them on any time from Settings → Notifications.';

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
  String get appLockBiometricOfferTitle => 'Unlock with fingerprint or face?';

  @override
  String get appLockBiometricOfferBody => 'Your PIN always works as a backup.';

  @override
  String get appLockBiometricUse => 'Use it';

  @override
  String get appLockBiometricSkip => 'Not now';

  @override
  String get appLockWrongPin => 'Wrong PIN — try again';

  @override
  String get appLockUseBiometric => 'Use fingerprint / face';

  @override
  String get appLockEnable => 'App lock';

  @override
  String get appLockEnableSub =>
      'Require a PIN (and biometrics) to open Productive Muslim';

  @override
  String get appLockDisable => 'Turn off app lock';

  @override
  String get appLockDelete => 'Delete last digit';

  @override
  String appLockThrottled(String time) {
    return 'Too many attempts. Try again in $time.';
  }

  @override
  String get appLockForgotPin => 'Forgot PIN?';

  @override
  String get appLockForgotReason => 'Confirm it\'s you to reset your app PIN';

  @override
  String get appLockNoDeviceLockTitle => 'Can\'t reset the PIN here';

  @override
  String get appLockNoDeviceLockBody =>
      'Your device has no screen lock, so we can\'t confirm it\'s you. Set up a screen lock in your device settings and try again. Clearing the app\'s data also removes the PIN, but erases your saved progress.';

  @override
  String get appLockNewPin => 'Set a new 4-digit PIN';

  @override
  String appLockPinProgress(int entered) {
    final intl.NumberFormat enteredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String enteredString = enteredNumberFormat.format(entered);

    return '$enteredString of 4 digits entered';
  }

  @override
  String a11yIncrease(String label) {
    return 'Increase $label';
  }

  @override
  String a11yDecrease(String label) {
    return 'Decrease $label';
  }

  @override
  String get prayerSheetWindow => 'Time window';

  @override
  String get prayerSheetRakaat => 'Rakaat';

  @override
  String get rakaatFard => 'Fard';

  @override
  String get rakaatSunnah => 'Sunnah';

  @override
  String get rakaatWitr => 'Witr';

  @override
  String get prayerSheetNoJamaat => 'No jamaat set';

  @override
  String get prayerFazilatFajr =>
      'The two sunnah of Fajr are better than the world and all it contains. Its prayer is witnessed by the angels of night and day.';

  @override
  String get prayerFazilatDhuhr =>
      'The gates of the heavens open at midday; the Prophet loved to pray four rakaat in that hour.';

  @override
  String get prayerFazilatAsr =>
      'Guard the middle prayer. Whoever prays Asr will not enter the Fire before sunrise and before sunset.';

  @override
  String get prayerFazilatMaghrib =>
      'Pray it early, as soon as the sun has set. Two light rakaat of sunnah follow the fard.';

  @override
  String get prayerFazilatIsha =>
      'Praying Isha in congregation is like standing half the night; joined with Fajr, like the whole night.';

  @override
  String get dailyKindAyah => 'Ayah';

  @override
  String get dailyAyahTitle => 'Ayah of the day';

  @override
  String get duaOfDayTitle => 'Dua of the day';

  @override
  String dailyAyahReference(String surah, String ayah) {
    return '$surah, ayah $ayah';
  }

  @override
  String get tasbihQuickTitle => 'Tasbih';

  @override
  String get tasbihQuickHint => 'Tap to count';

  @override
  String get qiblaChipLabel => 'Qibla';

  @override
  String get qiblaChipNeedsLocation => 'Set location';

  @override
  String get dayTimelineTitle => 'Today\'s timeline';

  @override
  String streakMilestone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString-day streak! 🎉';
  }

  @override
  String get calculatorsTitle => 'Calculators';

  @override
  String get calculatorsSubtitle => 'Zakat, fitra, qaza, inheritance & age';

  @override
  String get fitraTitle => 'Fitra calculator';

  @override
  String get fitraSubtitle => 'Calculate Sadaqatul Fitr for your household';

  @override
  String get fitraStaple => 'Staple food';

  @override
  String get fitraStapleWheat => 'Wheat / flour';

  @override
  String get fitraStapleBarley => 'Barley';

  @override
  String get fitraStapleDates => 'Dates';

  @override
  String get fitraStapleRaisins => 'Raisins';

  @override
  String get fitraPricePerKg => 'Price per kg';

  @override
  String get fitraPeople => 'Number of people';

  @override
  String get fitraCalculate => 'Calculate';

  @override
  String fitraPerPerson(String amount) {
    return 'Per person: $amount';
  }

  @override
  String fitraTotal(String amount) {
    return 'Total fitra: $amount';
  }

  @override
  String fitraWeightNote(String kg) {
    return 'Based on $kg kg per person';
  }

  @override
  String get fitraBeforeEid => 'Pay before the Eid prayer.';

  @override
  String get qazaTitle => 'Qaza prayer calculator';

  @override
  String get qazaSubtitle => 'Estimate missed obligatory prayers to make up';

  @override
  String get qazaStartDate => 'From date';

  @override
  String get qazaEndDate => 'To date';

  @override
  String get qazaSelectDate => 'Select date';

  @override
  String get qazaIncludeWitr => 'Include Witr (Hanafi)';

  @override
  String get qazaAlreadyMadeUp => 'Already made up (per prayer)';

  @override
  String get qazaEndBeforeStart => 'The end date is before the start date.';

  @override
  String get qazaCalculate => 'Calculate';

  @override
  String qazaDays(String count) {
    return 'Period: $count days';
  }

  @override
  String qazaPerPrayer(String count) {
    return 'Each prayer: $count';
  }

  @override
  String qazaWitr(String count) {
    return 'Witr: $count';
  }

  @override
  String qazaTotal(String count) {
    return 'Total missed: $count';
  }

  @override
  String get qazaNote =>
      'An estimate to help you plan — make them up steadily, without guilt.';

  @override
  String get ageTitle => 'Age calculator';

  @override
  String get ageSubtitle =>
      'Your age in both the Gregorian and Hijri calendars';

  @override
  String get ageBirthDate => 'Date of birth';

  @override
  String get ageAsOf => 'As of date';

  @override
  String get ageSelectDate => 'Select date';

  @override
  String get ageCalculate => 'Calculate';

  @override
  String get ageGregorian => 'Gregorian age';

  @override
  String get ageHijri => 'Hijri age';

  @override
  String ageValue(String years, String months, String days) {
    return '$years years, $months months, $days days';
  }

  @override
  String ageTotalDays(String count) {
    return 'Total: $count days';
  }

  @override
  String get faraidTitle => 'Inheritance calculator';

  @override
  String get faraidSubtitle => 'Estimate shares for common heirs (Faraid)';

  @override
  String get faraidEstate => 'Estate value';

  @override
  String get faraidSpouse => 'Spouse';

  @override
  String get faraidNone => 'None';

  @override
  String get faraidHusband => 'Husband';

  @override
  String get faraidWife => 'Wife';

  @override
  String get faraidWives => 'Number of wives';

  @override
  String get faraidFather => 'Father';

  @override
  String get faraidMother => 'Mother';

  @override
  String get faraidSons => 'Sons';

  @override
  String get faraidDaughters => 'Daughters';

  @override
  String get faraidBrothers => 'Full brothers';

  @override
  String get faraidSisters => 'Full sisters';

  @override
  String get faraidCalculate => 'Calculate';

  @override
  String faraidShare(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get faraidAwlNote =>
      'Shares exceed the estate — reduced proportionally (\'Awl).';

  @override
  String get faraidRaddNote => 'Surplus returned to the heirs (Radd).';

  @override
  String faraidUnallocated(String amount) {
    return 'Unallocated (to other relatives): $amount';
  }

  @override
  String get faraidDisclaimer =>
      'An estimate for common heirs only. Consult a qualified scholar for a binding ruling.';

  @override
  String get faraidHeirHusband => 'Husband';

  @override
  String get faraidHeirWife => 'Wife';

  @override
  String get faraidHeirFather => 'Father';

  @override
  String get faraidHeirMother => 'Mother';

  @override
  String get faraidHeirSon => 'Son';

  @override
  String get faraidHeirDaughter => 'Daughter';

  @override
  String get faraidHeirBrother => 'Brother';

  @override
  String get faraidHeirSister => 'Sister';

  @override
  String get hadithOfDayTitle => 'Hadith of the day';

  @override
  String get hadithTitle => 'Hadith';

  @override
  String get hadithNotFound => 'This hadith isn\'t available.';

  @override
  String get hadithSubtitle => 'Authentic narrations to reflect on';

  @override
  String hadithNarratedBy(String narrator) {
    return 'Narrated by $narrator';
  }

  @override
  String hadithTopicName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'intention': 'Intention & sincerity',
      'faith': 'Faith',
      'character': 'Character & manners',
      'speech': 'Speech & the tongue',
      'knowledge': 'Seeking knowledge',
      'charity': 'Charity & kindness',
      'mercy': 'Mercy & humility',
      'worship': 'Worship',
      'dunya': 'This world & the hereafter',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String hadithCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hadith',
      one: '1 hadith',
    );
    return '$_temp0';
  }

  @override
  String hadithChapterCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String get hadithBooksCardTitle => 'Full collections';

  @override
  String get hadithBooksTitle => 'Hadith collections';

  @override
  String get hadithBooksSubtitle =>
      'Browse the full books, fetched from an open dataset';

  @override
  String get hadithBookAllSahih => 'Every hadith authentic (Sahih)';

  @override
  String hadithGradeLabel(String grade) {
    return 'Grade: $grade';
  }

  @override
  String get hadithLoadError =>
      'Couldn\'t load. Check your connection and try again.';

  @override
  String get hadithRetry => 'Try again';

  @override
  String get hadithSourceNote =>
      'Source: fawazahmed0/hadith-api (public domain)';

  @override
  String get hadithSourceNoteBn => 'Bengali source: hadithbangla (open source)';

  @override
  String get hadithEnglishOnly => 'English only';

  @override
  String get hadithBengaliUnavailable =>
      'No Bengali translation — showing English';

  @override
  String get hadithBengaliUnavailableSection =>
      'Bengali isn\'t available for this book yet — showing English.';

  @override
  String get duaSearchHint => 'Search duas';

  @override
  String get duaSearchTitle => 'Search';

  @override
  String get duaNoResults => 'No duas found';

  @override
  String get duaFavoritesTitle => 'Favorites';

  @override
  String get duaFavoritesEmpty => 'Tap the heart on any dua to save it here';

  @override
  String get favoriteAddLabel => 'Add to favorites';

  @override
  String get favoriteRemoveLabel => 'Remove from favorites';

  @override
  String get widgetNextPrayerLabel => 'Next prayer';

  @override
  String get nearbyMosquesLabel => 'Mosques';

  @override
  String get nearbyMosquesLaunchError =>
      'Couldn\'t open Maps. Make sure a maps app is installed.';

  @override
  String get nearbyMosquesLocationError =>
      'Set your location first to find nearby mosques.';

  @override
  String get expenseTitle => 'Expense tracker';

  @override
  String get expenseSubtitle => 'Monthly hisab, no israf';

  @override
  String get expenseAdd => 'Add expense';

  @override
  String get expenseSave => 'Save';

  @override
  String get expenseAmountHint => 'Amount';

  @override
  String get expenseNoteHint => 'Note (optional)';

  @override
  String get expenseMonthTotal => 'Spent';

  @override
  String get expensePrevMonth => 'Previous month';

  @override
  String get expenseNextMonth => 'Next month';

  @override
  String get expenseEmpty => 'No expenses logged.';

  @override
  String get expenseIsrafReminder =>
      '“And those who, when they spend, are neither extravagant nor stingy, but hold a just balance between them.” (Al-Furqan 25:67)';

  @override
  String expenseCategory(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'need': 'Needs',
      'family': 'Family',
      'sadaqah': 'Sadaqah',
      'want': 'Wants',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get expenseEdit => 'Edit expense';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get expenseUndo => 'Undo';

  @override
  String get expenseSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get expenseAmountInvalid => 'Enter a whole amount';

  @override
  String get expenseBudget => 'Monthly budget';

  @override
  String get expenseBudgetClear => 'Remove budget';

  @override
  String expenseBudgetLeft(String left, String budget) {
    return '$left left of $budget';
  }

  @override
  String expenseBudgetOver(String amount) {
    return '$amount over budget — rethink the wants';
  }

  @override
  String expenseVsLastMonth(String dir, String amount) {
    String _temp0 = intl.Intl.selectLogic(dir, {
      'more': '$amount more than last month',
      'less': '$amount less than last month',
      'other': 'Same as last month',
    });
    return '$_temp0';
  }

  @override
  String expenseVsLastMonthSoFar(String dir, String amount) {
    String _temp0 = intl.Intl.selectLogic(dir, {
      'more': '$amount more than this time last month',
      'less': '$amount less than this time last month',
      'other': 'Same as this time last month',
    });
    return '$_temp0';
  }

  @override
  String get expenseYesterday => 'Yesterday';

  @override
  String get expenseCategoryBudgetHint =>
      'Tap a category to filter; hold to set its budget (sadaqah: a goal)';

  @override
  String expenseCategoryBudgetTitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'need': 'Needs budget',
      'family': 'Family budget',
      'sadaqah': 'Monthly sadaqah goal',
      'want': 'Wants budget',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get expenseBackup => 'Backup';

  @override
  String get expenseExportCsv => 'Copy CSV backup';

  @override
  String get expenseImportCsv => 'Restore from copied CSV';

  @override
  String get expenseExported =>
      'Copied. Paste it into Notes, email or a spreadsheet to keep it safe.';

  @override
  String get expenseImportInvalid =>
      'The clipboard doesn\'t hold an expense backup.';

  @override
  String expenseImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses restored',
      one: '1 expense restored',
      zero: 'Nothing new to restore',
    );
    return '$_temp0';
  }

  @override
  String get hadithSearchHint => 'Search hadith';

  @override
  String get hadithNoResults => 'No hadith found';

  @override
  String get ruqyahSearchHint => 'Search ruqyah';

  @override
  String get ruqyahNoResults => 'Nothing found';

  @override
  String get scheduleRuleRemoved => 'Schedule rule removed';

  @override
  String get countdownSeeDay => 'Full day';

  @override
  String get settingHomeCards => 'Home cards';

  @override
  String get settingHomeCardsSub => 'Choose which sections appear on Home';

  @override
  String get homeCardQuickActions => 'Quick actions';

  @override
  String get homeCardDaily => 'Ayah, hadith & dua of the day';

  @override
  String get focusHeader => 'Jamaat focus';

  @override
  String get focusToggle => 'Silent & lock at jamaat';

  @override
  String get focusToggleSub =>
      'Silences the phone and blocks other apps around jamaat. Needs jamaat times in My Mosque';

  @override
  String get focusToggleSubIos =>
      'iPhone doesn\'t let apps silence or lock the phone, so you\'ll get a reminder to switch to silent. Needs jamaat times in My Mosque';

  @override
  String get focusLeadLabel => 'Starts before jamaat';

  @override
  String get focusDurationLabel => 'Unlocks after';

  @override
  String get focusDurationManual => 'When I end it';

  @override
  String get focusPrayersLabel => 'Prayers';

  @override
  String get focusBlockToggle => 'Lock the phone';

  @override
  String get focusBlockToggleSub =>
      'Other apps are blocked; phone calls stay allowed';

  @override
  String get focusStrictToggle => 'Strict mode';

  @override
  String get focusStrictToggleSub =>
      'No early unlock, and these settings stay locked while a session runs';

  @override
  String get focusPermSilence =>
      'Allow Do Not Disturb access to silence the phone';

  @override
  String get focusPermBlock => 'Allow accessibility access to lock the phone';

  @override
  String get focusAllow => 'Allow';

  @override
  String get focusDisclosureTitle => 'Accessibility access';

  @override
  String get focusDisclosureBody =>
      'Productive Muslim uses the Accessibility service only during a jamaat focus session: to notice when another app opens and cover it with the jamaat screen. It does not read, collect or share anything you see or type.';

  @override
  String get focusContinue => 'Continue';

  @override
  String focusActiveUntil(String time) {
    return 'Jamaat focus is on until $time';
  }

  @override
  String get focusActive => 'Jamaat focus is on';

  @override
  String get focusStrictLocked =>
      'Strict mode — settings unlock when the session ends.';

  @override
  String get focusEndNow => 'End now';

  @override
  String notifFocusTitle(String prayer) {
    return '$prayer jamaat — time to focus';
  }

  @override
  String get notifFocusBody => 'Put your phone on silent and head to salah.';

  @override
  String get focusLockBody => 'Your phone is silenced for jamaat.';

  @override
  String focusLockBodyUntil(String time) {
    return 'Silenced for jamaat until $time';
  }

  @override
  String get focusEndAction => 'End';

  @override
  String get channelFocus => 'Jamaat focus';

  @override
  String get shortcutsGuideRow => 'Auto-silent with Shortcuts';

  @override
  String get shortcutsGuideRowSub =>
      'Set up your iPhone to silence itself at the mosque';

  @override
  String get shortcutsGuideTitle => 'Auto-silent on iPhone';

  @override
  String get shortcutsGuideIntro =>
      'The Shortcuts app can turn on Do Not Disturb for you. Set it up once:';

  @override
  String get shortcutsMosqueHeader => 'When you reach the mosque (recommended)';

  @override
  String get shortcutsMosqueStep1 =>
      'Open Shortcuts → Automation → + (New Automation).';

  @override
  String get shortcutsMosqueStep2 =>
      'Choose Arrive, pick your mosque\'s location, select Run Immediately, then tap Next.';

  @override
  String get shortcutsMosqueStep3 =>
      'Tap New Blank Automation → Add Action, and search for “Set Focus”.';

  @override
  String get shortcutsMosqueStep4 =>
      'Set it to: Turn Do Not Disturb On until I Leave. Tap Done.';

  @override
  String get shortcutsTimeHeader => 'At a fixed jamaat time';

  @override
  String get shortcutsTimeStep1 =>
      'Automation → + → Time of Day. Pick a few minutes before jamaat, Daily, Run Immediately.';

  @override
  String get shortcutsTimeStep2 =>
      'Add the “Set Focus” action: Turn Do Not Disturb On until a time after jamaat.';

  @override
  String get shortcutsTimeStep3 => 'Make one automation for each prayer.';

  @override
  String get shortcutsOpen => 'Open Shortcuts';
}
