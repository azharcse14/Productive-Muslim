import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// The application name shown in the launcher and app bars
  ///
  /// In en, this message translates to:
  /// **'Qalbee'**
  String get appTitle;

  /// Bottom navigation label for the Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Bottom navigation label for the Quran tab
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get tabQuran;

  /// Bottom navigation label for the Muhasaba tracker tab
  ///
  /// In en, this message translates to:
  /// **'Muhasaba'**
  String get tabMuhasaba;

  /// Bottom navigation label for the Dua & Tasbih tab
  ///
  /// In en, this message translates to:
  /// **'Dua'**
  String get tabDua;

  /// Bottom navigation label for the More/overflow tab
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// Placeholder body text on screens that are not built yet
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Title of the debug-only component gallery screen
  ///
  /// In en, this message translates to:
  /// **'Widget Gallery'**
  String get galleryTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @groupCalculation.
  ///
  /// In en, this message translates to:
  /// **'Prayer calculation'**
  String get groupCalculation;

  /// No description provided for @groupNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get groupNotifications;

  /// No description provided for @groupAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get groupAppearance;

  /// No description provided for @groupPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get groupPrivacy;

  /// No description provided for @groupAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get groupAbout;

  /// No description provided for @settingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingLocation;

  /// No description provided for @settingLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingLocationNotSet;

  /// No description provided for @settingMadhab.
  ///
  /// In en, this message translates to:
  /// **'Madhab (Asr)'**
  String get settingMadhab;

  /// No description provided for @settingMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get settingMethod;

  /// No description provided for @settingAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Minute adjustments'**
  String get settingAdjustments;

  /// No description provided for @settingAdjustmentsSub.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune each prayer ±minutes'**
  String get settingAdjustmentsSub;

  /// No description provided for @settingHighLat.
  ///
  /// In en, this message translates to:
  /// **'High-latitude rule'**
  String get settingHighLat;

  /// No description provided for @settingHighLatSub.
  ///
  /// In en, this message translates to:
  /// **'Advanced — for extreme latitudes'**
  String get settingHighLatSub;

  /// No description provided for @settingTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// No description provided for @settingAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingAppLock;

  /// No description provided for @settingRunSetup.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get settingRunSetup;

  /// No description provided for @settingCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits & attributions'**
  String get settingCredits;

  /// No description provided for @creditsBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are computed on-device. City database © GeoNames (CC BY 4.0). Fonts: Schibsted Grotesk, Noto Sans Bengali, IBM Plex Sans Arabic (OFL), KFGQPC Uthmanic Script HAFS © King Fahd Glorious Quran Printing Complex.'**
  String get creditsBody;

  /// No description provided for @madhabHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get madhabHanafi;

  /// No description provided for @madhabShafi.
  ///
  /// In en, this message translates to:
  /// **'Shafiʿi'**
  String get madhabShafi;

  /// No description provided for @madhabExplain.
  ///
  /// In en, this message translates to:
  /// **'Affects Asr time only'**
  String get madhabExplain;

  /// No description provided for @highLatMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle of the night'**
  String get highLatMiddle;

  /// No description provided for @highLatSeventh.
  ///
  /// In en, this message translates to:
  /// **'Seventh of the night'**
  String get highLatSeventh;

  /// No description provided for @highLatTwilight.
  ///
  /// In en, this message translates to:
  /// **'Twilight angle'**
  String get highLatTwilight;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority'**
  String get methodEgyptian;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'Univ. of Islamic Sciences, Karachi'**
  String get methodKarachi;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura (Makkah)'**
  String get methodUmmAlQura;

  /// No description provided for @methodDubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get methodDubai;

  /// No description provided for @methodQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodMoonsighting.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee'**
  String get methodMoonsighting;

  /// No description provided for @methodSingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore (MUIS)'**
  String get methodSingapore;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get methodNorthAmerica;

  /// No description provided for @methodTurkiye.
  ///
  /// In en, this message translates to:
  /// **'Türkiye (Diyanet)'**
  String get methodTurkiye;

  /// No description provided for @methodTehran.
  ///
  /// In en, this message translates to:
  /// **'Tehran (IGUT)'**
  String get methodTehran;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @locationUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locationUseGps;

  /// No description provided for @locationUseGpsSub.
  ///
  /// In en, this message translates to:
  /// **'GPS — works fully offline after the first fix'**
  String get locationUseGpsSub;

  /// No description provided for @locationChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose city manually'**
  String get locationChooseCity;

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search city…'**
  String get locationSearchHint;

  /// No description provided for @locationPrimingBody.
  ///
  /// In en, this message translates to:
  /// **'Qalbee uses your location only to compute prayer times and qibla direction on this device. Nothing ever leaves your phone.'**
  String get locationPrimingBody;

  /// No description provided for @locationDeniedFallback.
  ///
  /// In en, this message translates to:
  /// **'No problem — pick your city below and everything works the same.'**
  String get locationDeniedFallback;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Pick your city below, or enable location and try again.'**
  String get locationServiceOff;

  /// No description provided for @locationCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get locationCurrent;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching city — try a different spelling'**
  String get searchNoResults;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @countdownStartsIn.
  ///
  /// In en, this message translates to:
  /// **'{prayer} starts in'**
  String countdownStartsIn(String prayer);

  /// No description provided for @countdownJamaatIn.
  ///
  /// In en, this message translates to:
  /// **'Jamaat in'**
  String get countdownJamaatIn;

  /// No description provided for @countdownEndsIn.
  ///
  /// In en, this message translates to:
  /// **'{prayer} ends in'**
  String countdownEndsIn(String prayer);

  /// No description provided for @countdownSahriEnds.
  ///
  /// In en, this message translates to:
  /// **'Sahri ends in'**
  String get countdownSahriEnds;

  /// No description provided for @countdownIftarIn.
  ///
  /// In en, this message translates to:
  /// **'Iftar in'**
  String get countdownIftarIn;

  /// Caption under the countdown numeral, e.g. 'Jamaat at 5:15 pm'
  ///
  /// In en, this message translates to:
  /// **'{label} at {time}'**
  String subAt(String label, String time);

  /// No description provided for @jamaatLabel.
  ///
  /// In en, this message translates to:
  /// **'Jamaat'**
  String get jamaatLabel;

  /// No description provided for @sunriseLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunriseLabel;

  /// No description provided for @sahriEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sahri ends'**
  String get sahriEndsLabel;

  /// No description provided for @iftarLabel.
  ///
  /// In en, this message translates to:
  /// **'Iftar'**
  String get iftarLabel;

  /// No description provided for @setJamaat.
  ///
  /// In en, this message translates to:
  /// **'Set jamaat'**
  String get setJamaat;

  /// No description provided for @homeSetLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get homeSetLocationTitle;

  /// No description provided for @homeSetLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Pick your location once and Qalbee computes accurate prayer times for it — fully offline.'**
  String get homeSetLocationBody;

  /// No description provided for @homeSetLocationCta.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get homeSetLocationCta;

  /// No description provided for @hijriMonthName.
  ///
  /// In en, this message translates to:
  /// **'{month, select, m1{Muharram} m2{Safar} m3{Rabi al-Awwal} m4{Rabi al-Thani} m5{Jumada al-Ula} m6{Jumada al-Akhirah} m7{Rajab} m8{Shaban} m9{Ramadan} m10{Shawwal} m11{Dhul-Qadah} m12{Dhul-Hijjah} other{—}}'**
  String hijriMonthName(String month);

  /// No description provided for @banglaMonthName.
  ///
  /// In en, this message translates to:
  /// **'{month, select, m1{Boishakh} m2{Joishtho} m3{Asharh} m4{Srabon} m5{Bhadro} m6{Ashwin} m7{Kartik} m8{Ogrohayon} m9{Poush} m10{Magh} m11{Falgun} m12{Choitro} other{—}}'**
  String banglaMonthName(String month);

  /// No description provided for @notifAzanTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · {time}'**
  String notifAzanTitle(Object prayer, Object time);

  /// No description provided for @notifAzanBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer}.'**
  String notifAzanBody(Object prayer);

  /// No description provided for @notifJamaatTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} jamaat soon'**
  String notifJamaatTitle(Object prayer);

  /// No description provided for @notifJamaatBody.
  ///
  /// In en, this message translates to:
  /// **'Jamaat at {time}.'**
  String notifJamaatBody(Object time);

  /// No description provided for @notifSahriTitle.
  ///
  /// In en, this message translates to:
  /// **'Sahri ends soon'**
  String get notifSahriTitle;

  /// No description provided for @notifSahriBody.
  ///
  /// In en, this message translates to:
  /// **'Sahri ends at {time} — finish your meal in time.'**
  String notifSahriBody(Object time);

  /// No description provided for @notifIftarTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s iftar time'**
  String get notifIftarTitle;

  /// No description provided for @notifIftarBody.
  ///
  /// In en, this message translates to:
  /// **'May Allah accept your fast. Iftar at {time}.'**
  String notifIftarBody(Object time);

  /// No description provided for @notifMuhasabaTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening reflection'**
  String get notifMuhasabaTitle;

  /// No description provided for @notifMuhasabaBody.
  ///
  /// In en, this message translates to:
  /// **'A quiet minute for today\'s muhasaba?'**
  String get notifMuhasabaBody;

  /// No description provided for @notifMarkPrayed.
  ///
  /// In en, this message translates to:
  /// **'Mark as prayed'**
  String get notifMarkPrayed;

  /// No description provided for @channelAzan.
  ///
  /// In en, this message translates to:
  /// **'Azan'**
  String get channelAzan;

  /// No description provided for @channelReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get channelReminders;

  /// No description provided for @channelSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent prayer alerts'**
  String get channelSilent;

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSettingsTitle;

  /// No description provided for @notifPermissionDeniedBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in system settings. Qalbee stays fully useful — enable them to get azan and reminders.'**
  String get notifPermissionDeniedBanner;

  /// No description provided for @notifEnableCta.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notifEnableCta;

  /// No description provided for @notifExactAlarmBanner.
  ///
  /// In en, this message translates to:
  /// **'For azan at the exact minute, allow \"Alarms & reminders\" for Qalbee in system settings.'**
  String get notifExactAlarmBanner;

  /// No description provided for @notifExactAlarmCta.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get notifExactAlarmCta;

  /// No description provided for @notifBatteryHint.
  ///
  /// In en, this message translates to:
  /// **'If reminders arrive late, exclude Qalbee from battery optimization in system settings.'**
  String get notifBatteryHint;

  /// No description provided for @notifPerPrayerHeader.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get notifPerPrayerHeader;

  /// No description provided for @azanModeAzan.
  ///
  /// In en, this message translates to:
  /// **'Azan'**
  String get azanModeAzan;

  /// No description provided for @azanModeBeep.
  ///
  /// In en, this message translates to:
  /// **'Beep'**
  String get azanModeBeep;

  /// No description provided for @azanModeSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get azanModeSilent;

  /// No description provided for @azanModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get azanModeOff;

  /// No description provided for @notifSahriToggle.
  ///
  /// In en, this message translates to:
  /// **'Sahri warning'**
  String get notifSahriToggle;

  /// No description provided for @notifSahriToggleSub.
  ///
  /// In en, this message translates to:
  /// **'Before sahri ends'**
  String get notifSahriToggleSub;

  /// No description provided for @notifIftarToggle.
  ///
  /// In en, this message translates to:
  /// **'Iftar alert'**
  String get notifIftarToggle;

  /// No description provided for @notifIftarToggleSub.
  ///
  /// In en, this message translates to:
  /// **'At maghrib, with a celebratory tone'**
  String get notifIftarToggleSub;

  /// No description provided for @notifJamaatToggle.
  ///
  /// In en, this message translates to:
  /// **'Jamaat reminder'**
  String get notifJamaatToggle;

  /// No description provided for @notifJamaatToggleSub.
  ///
  /// In en, this message translates to:
  /// **'Needs jamaat times in My Mosque'**
  String get notifJamaatToggleSub;

  /// No description provided for @notifMuhasabaToggle.
  ///
  /// In en, this message translates to:
  /// **'Evening muhasaba nudge'**
  String get notifMuhasabaToggle;

  /// No description provided for @notifMuhasabaToggleSub.
  ///
  /// In en, this message translates to:
  /// **'One gentle reminder after Isha'**
  String get notifMuhasabaToggleSub;

  /// No description provided for @leadTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Lead time'**
  String get leadTimeLabel;

  /// No description provided for @myMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'My Mosque'**
  String get myMosqueTitle;

  /// No description provided for @myMosqueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jamaat times for your mosque'**
  String get myMosqueSubtitle;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get addProfile;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Mosque name (e.g. Home, Work)'**
  String get profileNameHint;

  /// No description provided for @defaultProfileName.
  ///
  /// In en, this message translates to:
  /// **'My Mosque'**
  String get defaultProfileName;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Its jamaat times will be removed.'**
  String deleteProfileConfirm(String name);

  /// No description provided for @jamaatModeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get jamaatModeNone;

  /// No description provided for @jamaatModeOffset.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get jamaatModeOffset;

  /// No description provided for @jamaatModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get jamaatModeFixed;

  /// No description provided for @offsetAfterStart.
  ///
  /// In en, this message translates to:
  /// **'{count} min after waqt starts'**
  String offsetAfterStart(int count);

  /// No description provided for @fixedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Jamaat at {time}'**
  String fixedAtTime(String time);

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get pickTime;

  /// No description provided for @jamaatReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Jamaat reminders are configured under Notifications.'**
  String get jamaatReminderHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// No description provided for @qiblaAligned.
  ///
  /// In en, this message translates to:
  /// **'Facing the Qibla'**
  String get qiblaAligned;

  /// No description provided for @qiblaHeading.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° {cardinal}'**
  String qiblaHeading(String degrees, String cardinal);

  /// No description provided for @qiblaDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km to the Kaaba'**
  String qiblaDistance(String km);

  /// No description provided for @qiblaCalibrate.
  ///
  /// In en, this message translates to:
  /// **'Move your phone in a figure-8 to calibrate the compass'**
  String get qiblaCalibrate;

  /// No description provided for @qiblaSensorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Compass sensor unavailable on this device'**
  String get qiblaSensorUnavailable;

  /// No description provided for @qiblaVerbalBearing.
  ///
  /// In en, this message translates to:
  /// **'Qibla is at {degrees}° {cardinal} from north'**
  String qiblaVerbalBearing(String degrees, String cardinal);

  /// No description provided for @qiblaNeedsLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location to find the qibla direction'**
  String get qiblaNeedsLocation;

  /// No description provided for @muhasabaTitle.
  ///
  /// In en, this message translates to:
  /// **'Muhasaba'**
  String get muhasabaTitle;

  /// No description provided for @muhasabaFirstDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily muhasaba'**
  String get muhasabaFirstDayTitle;

  /// No description provided for @muhasabaFirstDayBody.
  ///
  /// In en, this message translates to:
  /// **'Muhasaba is gentle self-accounting: small daily deeds, tracked kindly. Check off what you did — every bit counts.'**
  String get muhasabaFirstDayBody;

  /// No description provided for @muhasabaStart.
  ///
  /// In en, this message translates to:
  /// **'Bismillah, let\'s begin'**
  String get muhasabaStart;

  /// No description provided for @trackerName.
  ///
  /// In en, this message translates to:
  /// **'{key, select, salah_fajr{Fajr prayer} salah_dhuhr{Dhuhr prayer} salah_asr{Asr prayer} salah_maghrib{Maghrib prayer} salah_isha{Isha prayer} quran{Quran reading} azkar{Azkar} sadaqah{Sadaqah} tahajjud{Tahajjud} roza{Fasting} other{{key}}}'**
  String trackerName(String key);

  /// No description provided for @addTracker.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addTracker;

  /// No description provided for @editTracker.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editTracker;

  /// No description provided for @trackerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Morning adhkar)'**
  String get trackerNameHint;

  /// No description provided for @trackerKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get trackerKindLabel;

  /// No description provided for @kindYesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes / No'**
  String get kindYesNo;

  /// No description provided for @kindCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get kindCount;

  /// No description provided for @kindDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get kindDuration;

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily target (optional)'**
  String get targetLabel;

  /// No description provided for @targetCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get targetCountSuffix;

  /// No description provided for @targetMinutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get targetMinutesSuffix;

  /// No description provided for @archiveTracker.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTracker;

  /// No description provided for @unarchiveTracker.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get unarchiveTracker;

  /// No description provided for @archiveExplain.
  ///
  /// In en, this message translates to:
  /// **'Archived items disappear from your daily list, but every past entry is preserved.'**
  String get archiveExplain;

  /// No description provided for @archivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedSection;

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTab;

  /// No description provided for @todayTab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @overallCompletion.
  ///
  /// In en, this message translates to:
  /// **'Overall completion'**
  String get overallCompletion;

  /// No description provided for @currentStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String currentStreakLabel(int count);

  /// No description provided for @bestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Best: {count}'**
  String bestStreakLabel(int count);

  /// No description provided for @vsPrevious.
  ///
  /// In en, this message translates to:
  /// **'{trend, select, up{Better than the last period} same{Steady as the last period} down{A fresh start — keep going} other{—}}'**
  String vsPrevious(String trend);

  /// No description provided for @emptyRange.
  ///
  /// In en, this message translates to:
  /// **'No entries in this range yet'**
  String get emptyRange;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesValue(int count);

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
