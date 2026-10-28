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
  /// **'Productive Muslim'**
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

  /// No description provided for @moreGroupWorship.
  ///
  /// In en, this message translates to:
  /// **'Worship'**
  String get moreGroupWorship;

  /// No description provided for @moreGroupTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get moreGroupTools;

  /// No description provided for @moreGroupYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get moreGroupYou;

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

  /// No description provided for @settingHijriOffset.
  ///
  /// In en, this message translates to:
  /// **'Hijri date adjustment'**
  String get settingHijriOffset;

  /// No description provided for @settingHijriOffsetSub.
  ///
  /// In en, this message translates to:
  /// **'Match your local moon-sighting'**
  String get settingHijriOffsetSub;

  /// No description provided for @hijriOffsetValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{sign}1 day} other{{sign}{count} days}}'**
  String hijriOffsetValue(int count, String sign);

  /// No description provided for @settingSahriSafety.
  ///
  /// In en, this message translates to:
  /// **'Sahri safety margin'**
  String get settingSahriSafety;

  /// No description provided for @settingSahriSafetySub.
  ///
  /// In en, this message translates to:
  /// **'End sahri this many minutes before Fajr'**
  String get settingSahriSafetySub;

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

  /// No description provided for @settingShowAchievements.
  ///
  /// In en, this message translates to:
  /// **'Show achievements'**
  String get settingShowAchievements;

  /// No description provided for @settingShowAchievementsSub.
  ///
  /// In en, this message translates to:
  /// **'Badges and streak milestones in Muhasaba'**
  String get settingShowAchievementsSub;

  /// No description provided for @settingHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingHaptics;

  /// No description provided for @settingHapticsSub.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on taps and tasbih counts'**
  String get settingHapticsSub;

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

  /// No description provided for @madhabMaliki.
  ///
  /// In en, this message translates to:
  /// **'Maliki'**
  String get madhabMaliki;

  /// No description provided for @madhabHanbali.
  ///
  /// In en, this message translates to:
  /// **'Hanbali'**
  String get madhabHanbali;

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

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSystemSettings;

  /// No description provided for @locationSearchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search cities. Please try again.'**
  String get locationSearchError;

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search city…'**
  String get locationSearchHint;

  /// No description provided for @locationPrimingBody.
  ///
  /// In en, this message translates to:
  /// **'Productive Muslim uses your location on this device to calculate prayer times and the qibla direction. It is shared only if you choose to open nearby mosques in Maps.'**
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

  /// No description provided for @sunsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunsetLabel;

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

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Peaceful night'**
  String get greetingNight;

  /// No description provided for @continueReadingAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String continueReadingAyah(String number);

  /// No description provided for @forbiddenTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Forbidden times'**
  String get forbiddenTimesTitle;

  /// No description provided for @naflTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nafl times'**
  String get naflTimesTitle;

  /// No description provided for @specialNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get specialNow;

  /// No description provided for @specialTimeForbiddenSunrise.
  ///
  /// In en, this message translates to:
  /// **'After sunrise'**
  String get specialTimeForbiddenSunrise;

  /// No description provided for @specialTimeForbiddenZawal.
  ///
  /// In en, this message translates to:
  /// **'Midday (zawal)'**
  String get specialTimeForbiddenZawal;

  /// No description provided for @specialTimeForbiddenSunset.
  ///
  /// In en, this message translates to:
  /// **'Before sunset'**
  String get specialTimeForbiddenSunset;

  /// No description provided for @specialTimeIshraq.
  ///
  /// In en, this message translates to:
  /// **'Ishraq'**
  String get specialTimeIshraq;

  /// No description provided for @specialTimeDuha.
  ///
  /// In en, this message translates to:
  /// **'Duha (Chasht)'**
  String get specialTimeDuha;

  /// No description provided for @specialTimeSalatZawal.
  ///
  /// In en, this message translates to:
  /// **'Salat al-Zawal'**
  String get specialTimeSalatZawal;

  /// No description provided for @specialTimeAwwabin.
  ///
  /// In en, this message translates to:
  /// **'Awwabin'**
  String get specialTimeAwwabin;

  /// No description provided for @specialTimeTahajjud.
  ///
  /// In en, this message translates to:
  /// **'Tahajjud'**
  String get specialTimeTahajjud;

  /// No description provided for @forbiddenTimesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No salah may be offered in these three moments.'**
  String get forbiddenTimesSubtitle;

  /// No description provided for @naflTimesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Best times for voluntary (nafl) prayers.'**
  String get naflTimesSubtitle;

  /// No description provided for @specialTimesLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get specialTimesLearnMore;

  /// No description provided for @specialTimesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Forbidden & nafl times'**
  String get specialTimesPageTitle;

  /// No description provided for @forbiddenTimesIntro.
  ///
  /// In en, this message translates to:
  /// **'There are three moments in the day when offering any salah is prohibited (makruh tahrimi). The Prophet ﷺ forbade praying as the sun rises, at its zenith, and as it sets — the times the disbelievers worshipped the sun. Missed obligatory prayers remembered in these windows may still be made up.'**
  String get forbiddenTimesIntro;

  /// No description provided for @naflTimesIntro.
  ///
  /// In en, this message translates to:
  /// **'Beyond the obligatory prayers, these are recommended voluntary (nafl) prayers with their preferred times — a means of drawing nearer to Allah and making up for shortcomings in the fard.'**
  String get naflTimesIntro;

  /// No description provided for @specialDetailForbiddenSunrise.
  ///
  /// In en, this message translates to:
  /// **'From sunrise until the sun has fully risen above the horizon (about 15 minutes). The Prophet ﷺ said the sun rises between the two horns of Shaytan, so salah is withheld until it clears.'**
  String get specialDetailForbiddenSunrise;

  /// No description provided for @specialDetailForbiddenZawal.
  ///
  /// In en, this message translates to:
  /// **'The brief moment the sun stands at its highest point (istiwa) before passing the meridian into the Dhuhr time. No salah is offered until it begins to decline.'**
  String get specialDetailForbiddenZawal;

  /// No description provided for @specialDetailForbiddenSunset.
  ///
  /// In en, this message translates to:
  /// **'From when the sun yellows and starts to set until it has fully set (Maghrib). As at sunrise, salah is withheld while the sun sets.'**
  String get specialDetailForbiddenSunset;

  /// No description provided for @specialDetailIshraq.
  ///
  /// In en, this message translates to:
  /// **'Two rak\'ahs offered shortly after the sun has fully risen. Whoever prays Fajr in congregation, sits in dhikr until sunrise, then prays two rak\'ahs earns the reward of a complete Hajj and Umrah.'**
  String get specialDetailIshraq;

  /// No description provided for @specialDetailDuha.
  ///
  /// In en, this message translates to:
  /// **'The forenoon prayer of two to twelve rak\'ahs, best offered once the sun has risen high, lasting until just before zawal. A charity is due for every joint of the body each morning, and these rak\'ahs suffice for it.'**
  String get specialDetailDuha;

  /// No description provided for @specialDetailSalatZawal.
  ///
  /// In en, this message translates to:
  /// **'Offered right after the sun passes its zenith and begins to decline, just before the Dhuhr fard. The Prophet ﷺ used to pray when the gates of heaven are opened at this hour.'**
  String get specialDetailSalatZawal;

  /// No description provided for @specialDetailAwwabin.
  ///
  /// In en, this message translates to:
  /// **'Voluntary rak\'ahs offered between the Maghrib and Isha prayers — the salah of the oft-returning (awwabin), beloved for turning back to Allah after the day\'s work.'**
  String get specialDetailAwwabin;

  /// No description provided for @specialDetailTahajjud.
  ///
  /// In en, this message translates to:
  /// **'Night prayer in the last third of the night, the most virtuous voluntary salah. It is the hour Allah descends to the lowest heaven, answering the one who calls upon Him.'**
  String get specialDetailTahajjud;

  /// No description provided for @setJamaat.
  ///
  /// In en, this message translates to:
  /// **'Set jamaat time'**
  String get setJamaat;

  /// No description provided for @switchMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Jamaat mosque'**
  String get switchMosqueTitle;

  /// No description provided for @mosqueAutoBadge.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get mosqueAutoBadge;

  /// No description provided for @mosqueOverrideBadge.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get mosqueOverrideBadge;

  /// No description provided for @mosqueAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switching automatically by your schedule'**
  String get mosqueAutoSubtitle;

  /// No description provided for @mosqueOverrideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary override — reset to resume the schedule'**
  String get mosqueOverrideSubtitle;

  /// No description provided for @mosqueResetToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Reset to schedule'**
  String get mosqueResetToSchedule;

  /// No description provided for @mosqueManage.
  ///
  /// In en, this message translates to:
  /// **'Manage mosques & schedule'**
  String get mosqueManage;

  /// No description provided for @scheduleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-switch'**
  String get scheduleSectionTitle;

  /// No description provided for @scheduleModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get scheduleModeManual;

  /// No description provided for @scheduleModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get scheduleModeAuto;

  /// No description provided for @scheduleAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Productive Muslim picks the mosque by day and time.'**
  String get scheduleAutoHint;

  /// No description provided for @scheduleRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get scheduleRulesTitle;

  /// No description provided for @scheduleRulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Add one to switch automatically.'**
  String get scheduleRulesEmpty;

  /// No description provided for @scheduleAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get scheduleAddRule;

  /// No description provided for @scheduleDefaultMosque.
  ///
  /// In en, this message translates to:
  /// **'Default mosque'**
  String get scheduleDefaultMosque;

  /// No description provided for @scheduleDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Used when no rule matches.'**
  String get scheduleDefaultHint;

  /// No description provided for @scheduleAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get scheduleAllDay;

  /// No description provided for @scheduleEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get scheduleEveryDay;

  /// No description provided for @scheduleFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get scheduleFrom;

  /// No description provided for @scheduleTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get scheduleTo;

  /// No description provided for @weekdayShort.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 1{Mon} 2{Tue} 3{Wed} 4{Thu} 5{Fri} 6{Sat} 7{Sun} other{}}'**
  String weekdayShort(String day);

  /// No description provided for @homeSetLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get homeSetLocationTitle;

  /// No description provided for @homeSetLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Pick your location once and Productive Muslim computes accurate prayer times for it — fully offline.'**
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

  /// No description provided for @notifKeepAliveTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders running'**
  String get notifKeepAliveTitle;

  /// No description provided for @notifKeepAliveBody.
  ///
  /// In en, this message translates to:
  /// **'Open Productive Muslim when you have a moment, so your prayer reminders continue.'**
  String get notifKeepAliveBody;

  /// No description provided for @notifScheduledUntil.
  ///
  /// In en, this message translates to:
  /// **'Reminders scheduled until {when}'**
  String notifScheduledUntil(String when);

  /// No description provided for @notifScheduledNone.
  ///
  /// In en, this message translates to:
  /// **'No reminders are scheduled right now.'**
  String get notifScheduledNone;

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

  /// No description provided for @channelBeep.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts (beep)'**
  String get channelBeep;

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSettingsTitle;

  /// No description provided for @notifPermissionDeniedBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in system settings. Productive Muslim stays fully useful — enable them to get azan and reminders.'**
  String get notifPermissionDeniedBanner;

  /// No description provided for @notifEnableCta.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notifEnableCta;

  /// No description provided for @notifExactAlarmBanner.
  ///
  /// In en, this message translates to:
  /// **'For azan at the exact minute, allow \"Alarms & reminders\" for Productive Muslim in system settings.'**
  String get notifExactAlarmBanner;

  /// No description provided for @notifExactAlarmCta.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get notifExactAlarmCta;

  /// No description provided for @notifBatteryHint.
  ///
  /// In en, this message translates to:
  /// **'If reminders arrive late, exclude Productive Muslim from battery optimization in system settings.'**
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

  /// No description provided for @notifDailyToggle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get notifDailyToggle;

  /// No description provided for @notifDailyToggleSub.
  ///
  /// In en, this message translates to:
  /// **'A hadith or dua of the day, at your time'**
  String get notifDailyToggleSub;

  /// No description provided for @notifDailyKindHadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get notifDailyKindHadith;

  /// No description provided for @notifDailyKindDua.
  ///
  /// In en, this message translates to:
  /// **'Dua'**
  String get notifDailyKindDua;

  /// No description provided for @notifDailyTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notifDailyTimeLabel;

  /// No description provided for @notifDailyHadithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith of the day'**
  String get notifDailyHadithTitle;

  /// No description provided for @notifDailyHadithBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s hadith is ready — tap to read it.'**
  String get notifDailyHadithBody;

  /// No description provided for @notifDailyDuaTitle.
  ///
  /// In en, this message translates to:
  /// **'Dua of the day'**
  String get notifDailyDuaTitle;

  /// No description provided for @notifDailyDuaBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s dua is ready — tap to read it.'**
  String get notifDailyDuaBody;

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

  /// No description provided for @qiblaFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding direction…'**
  String get qiblaFinding;

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

  /// No description provided for @muhasabaDayComplete.
  ///
  /// In en, this message translates to:
  /// **'Every deed done today — alhamdulillah'**
  String get muhasabaDayComplete;

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

  /// No description provided for @salahLockedToast.
  ///
  /// In en, this message translates to:
  /// **'This prayer\'s time hasn\'t started yet'**
  String get salahLockedToast;

  /// No description provided for @a11yMarkPrayed.
  ///
  /// In en, this message translates to:
  /// **'Mark {prayer} as prayed'**
  String a11yMarkPrayed(String prayer);

  /// No description provided for @a11yPrayerLocked.
  ///
  /// In en, this message translates to:
  /// **'{prayer}: its time hasn\'t started yet'**
  String a11yPrayerLocked(String prayer);

  /// No description provided for @muhasabaDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String muhasabaDoneCount(int done, int total);

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

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// No description provided for @searchSurahHint.
  ///
  /// In en, this message translates to:
  /// **'Search surah…'**
  String get searchSurahHint;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @surahMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs · {place}'**
  String surahMeta(int count, String place);

  /// No description provided for @revelationName.
  ///
  /// In en, this message translates to:
  /// **'{place, select, meccan{Meccan} medinan{Medinan} other{—}}'**
  String revelationName(String place);

  /// No description provided for @readerFontSize.
  ///
  /// In en, this message translates to:
  /// **'Arabic text size'**
  String get readerFontSize;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readerSettings;

  /// No description provided for @copyAyah.
  ///
  /// In en, this message translates to:
  /// **'Copy ayah'**
  String get copyAyah;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @quranLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the Quran text. Please try again.'**
  String get quranLoadError;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedLabel;

  /// No description provided for @ayahCopied.
  ///
  /// In en, this message translates to:
  /// **'Ayah copied'**
  String get ayahCopied;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @bookmarksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet. Tap the bookmark icon on any ayah to save it here.'**
  String get bookmarksEmpty;

  /// No description provided for @bookmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmarkLabel;

  /// No description provided for @quranFirstOpen.
  ///
  /// In en, this message translates to:
  /// **'Bismillah — start reading and Productive Muslim will remember where you left off.'**
  String get quranFirstOpen;

  /// No description provided for @ayahShareSuffix.
  ///
  /// In en, this message translates to:
  /// **'— Quran {surah}:{ayah}'**
  String ayahShareSuffix(int surah, int ayah);

  /// No description provided for @duaTitle.
  ///
  /// In en, this message translates to:
  /// **'Dua & Tasbih'**
  String get duaTitle;

  /// No description provided for @tasbihTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihTitle;

  /// No description provided for @asmaulHusnaTitle.
  ///
  /// In en, this message translates to:
  /// **'Asmaul Husna'**
  String get asmaulHusnaTitle;

  /// No description provided for @asmaQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Names quiz'**
  String get asmaQuizTitle;

  /// No description provided for @asmaLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the names. Please try again later.'**
  String get asmaLoadError;

  /// No description provided for @asmaQuizModeNameToMeaning.
  ///
  /// In en, this message translates to:
  /// **'Name → meaning'**
  String get asmaQuizModeNameToMeaning;

  /// No description provided for @asmaQuizModeMeaningToName.
  ///
  /// In en, this message translates to:
  /// **'Meaning → name'**
  String get asmaQuizModeMeaningToName;

  /// No description provided for @asmaQuizPromptMeaning.
  ///
  /// In en, this message translates to:
  /// **'What is the meaning of this name?'**
  String get asmaQuizPromptMeaning;

  /// No description provided for @asmaQuizPromptName.
  ///
  /// In en, this message translates to:
  /// **'Which name has this meaning?'**
  String get asmaQuizPromptName;

  /// No description provided for @asmaQuizProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String asmaQuizProgress(int current, int total);

  /// No description provided for @asmaQuizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get asmaQuizNext;

  /// No description provided for @asmaQuizSeeResult.
  ///
  /// In en, this message translates to:
  /// **'See result'**
  String get asmaQuizSeeResult;

  /// No description provided for @asmaQuizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz complete'**
  String get asmaQuizResultTitle;

  /// No description provided for @asmaQuizResultEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Every name you revisit draws you closer. There\'s no pass or fail here — return whenever you like and try again.'**
  String get asmaQuizResultEncouragement;

  /// No description provided for @asmaQuizScore.
  ///
  /// In en, this message translates to:
  /// **'{score}/{total}'**
  String asmaQuizScore(int score, int total);

  /// No description provided for @asmaQuizBest.
  ///
  /// In en, this message translates to:
  /// **'Best score: {best}'**
  String asmaQuizBest(int best);

  /// No description provided for @asmaQuizPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get asmaQuizPlayAgain;

  /// No description provided for @fastingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunnah fasting'**
  String get fastingTitle;

  /// No description provided for @fastingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended days & your log'**
  String get fastingSubtitle;

  /// No description provided for @fastingTodayRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended fast today'**
  String get fastingTodayRecommended;

  /// No description provided for @fastingTodayNone.
  ///
  /// In en, this message translates to:
  /// **'No recommended fast today'**
  String get fastingTodayNone;

  /// No description provided for @fastingTodayNoneNote.
  ///
  /// In en, this message translates to:
  /// **'There is no specific sunnah fast today, but a voluntary fast is always rewarded.'**
  String get fastingTodayNoneNote;

  /// No description provided for @fastingTodayForbidden.
  ///
  /// In en, this message translates to:
  /// **'Fasting is not permitted today'**
  String get fastingTodayForbidden;

  /// No description provided for @fastingTodayForbiddenNote.
  ///
  /// In en, this message translates to:
  /// **'Fasting is forbidden on the two Eids and the days of Tashreeq (11–13 Dhul-Hijjah).'**
  String get fastingTodayForbiddenNote;

  /// No description provided for @fastingTodayRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan — the obligatory fast'**
  String get fastingTodayRamadan;

  /// No description provided for @fastingTodayRamadanNote.
  ///
  /// In en, this message translates to:
  /// **'Today is a day of Ramadan, an obligatory fast. May Allah accept it.'**
  String get fastingTodayRamadanNote;

  /// No description provided for @fastingLogToday.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get fastingLogToday;

  /// No description provided for @fastingLogVoluntary.
  ///
  /// In en, this message translates to:
  /// **'Log a voluntary fast'**
  String get fastingLogVoluntary;

  /// No description provided for @fastingLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'Logged for today'**
  String get fastingLoggedToday;

  /// No description provided for @fastingLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your fasting log'**
  String get fastingLogTitle;

  /// No description provided for @fastingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get fastingTotal;

  /// No description provided for @fastingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get fastingThisMonth;

  /// No description provided for @fastingThisHijriMonth.
  ///
  /// In en, this message translates to:
  /// **'This hijri month'**
  String get fastingThisHijriMonth;

  /// No description provided for @fastingFasted.
  ///
  /// In en, this message translates to:
  /// **'Fasted'**
  String get fastingFasted;

  /// No description provided for @fastingHeatmapLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No fasts logged this month} =1{1 fast logged this month} other{{count} fasts logged this month}}'**
  String fastingHeatmapLabel(int count);

  /// No description provided for @fastingUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming recommended fasts'**
  String get fastingUpcomingTitle;

  /// No description provided for @fastingKindName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, mondayThursday{Monday & Thursday} whiteDays{White days (Ayyam al-Beed)} ashura{Ashura} arafah{Day of Arafah} dhulHijjah{First ten days of Dhul-Hijjah} shawwal{Six days of Shawwal} other{{id}}}'**
  String fastingKindName(String id);

  /// No description provided for @fastingKindNote.
  ///
  /// In en, this message translates to:
  /// **'{id, select, mondayThursday{Deeds are presented to Allah on Mondays and Thursdays, and the Prophet ﷺ loved to be fasting then. (Tirmidhi)} whiteDays{Fasting the 13th, 14th and 15th of each hijri month is like fasting the whole year. (Nasa\'i)} ashura{Fasting Ashura expiates the sins of the past year; fast the 9th with it. (Muslim)} arafah{Fasting the Day of Arafah expiates the past and the coming year. (Muslim)} dhulHijjah{No good deeds are more beloved to Allah than those done in these ten days. (Bukhari)} shawwal{Fasting Ramadan then six days of Shawwal is like fasting the entire year. (Muslim)} other{}}'**
  String fastingKindNote(String id);

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every small step counts — keep going.'**
  String get achievementsSubtitle;

  /// No description provided for @achievementHow.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, streak{Log at least one deed in Muhasaba {count} days in a row.} salah{Check off a salah on {count} different days.} dhikr{Count and save {count} dhikr with the tasbih.} quranStart{Open the Quran and start reading.} quran{Complete your Quran reading on {count} days.} bookmark{Bookmark {count} ayahs.} fast{Log {count} fasts.} other{Keep going.}}'**
  String achievementHow(String kind, String count);

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementUnlocked;

  /// No description provided for @achievementsCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} earned'**
  String achievementsCount(int unlocked, int total);

  /// No description provided for @achievementCategory.
  ///
  /// In en, this message translates to:
  /// **'{key, select, streaks{Streaks} salah{Salah} dhikr{Dhikr} quran{Quran} fasting{Fasting} other{Achievements}}'**
  String achievementCategory(String key);

  /// No description provided for @achievementName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, streak_3{Three in a row} streak_7{A steady week} streak_30{A month of devotion} streak_100{A hundred days} salah_10{Ten days of salah} salah_50{Fifty days of salah} salah_200{Two hundred days of salah} dhikr_100{First hundred dhikr} dhikr_1000{A thousand dhikr} dhikr_10000{Ten thousand dhikr} quran_start{Opened the Quran} quran_days_7{A week with the Quran} quran_days_30{A month with the Quran} quran_bookmark_5{Five bookmarks} fast_1{First fast} fast_10{Ten fasts} fast_30{Thirty fasts} other{Achievement}}'**
  String achievementName(String id);

  /// No description provided for @duaCategoryName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, morning_evening{Morning & evening} sleep{Sleep} waking{Waking up} food{Food & drink} home{Entering & leaving home} travel{Travel} salah{Salah} distress{Distress & relief} wudu{Wudu} clothes{Dressing} weather{Rain & weather} istighfar{Seeking forgiveness} gratitude{Gratitude} protection{Protection} sneezing{Sneezing} marketplace{Marketplace} adhan{Adhan & iqamah} toilet{Toilet} knowledge{Knowledge & guidance} family{Family & marriage} other{{id}}}'**
  String duaCategoryName(String id);

  /// No description provided for @duaCount.
  ///
  /// In en, this message translates to:
  /// **'{count} duas'**
  String duaCount(int count);

  /// No description provided for @repeatTimes.
  ///
  /// In en, this message translates to:
  /// **'Repeat {count}×'**
  String repeatTimes(int count);

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get referenceLabel;

  /// No description provided for @ruqyahTitle.
  ///
  /// In en, this message translates to:
  /// **'Ruqyah'**
  String get ruqyahTitle;

  /// No description provided for @ruqyahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Qur\'anic protection & healing'**
  String get ruqyahSubtitle;

  /// No description provided for @ruqyahHowToTitle.
  ///
  /// In en, this message translates to:
  /// **'How to perform ruqyah'**
  String get ruqyahHowToTitle;

  /// No description provided for @ruqyahHowToBody.
  ///
  /// In en, this message translates to:
  /// **'Recite these verses and supplications sincerely, with full trust that healing is from Allah alone. Blow lightly over yourself or the one being treated, or over water to drink. Ruqyah is from the Qur\'an and authentic Sunnah only — never seek out amulets or sorcerers.'**
  String get ruqyahHowToBody;

  /// No description provided for @ruqyahCategoryName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, protection{Protection} three_quls{The three Quls} healing{Healing & sickness} evil_eye{Evil eye & envy} sihr_jinn{Sihr, jinn & whispers} anxiety_grief{Anxiety, grief & distress} sleep{Sleep & nightmares} morning_evening{Morning & evening} enemies{Enemies & oppressors} children{Protecting children} fitan{Trials & the Dajjal} other{{id}}}'**
  String ruqyahCategoryName(String id);

  /// No description provided for @ruqyahCount.
  ///
  /// In en, this message translates to:
  /// **'{count} passages'**
  String ruqyahCount(int count);

  /// No description provided for @tasbihTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get tasbihTarget;

  /// No description provided for @tasbihCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get tasbihCustom;

  /// No description provided for @tasbihReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// No description provided for @tasbihDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get tasbihDiscard;

  /// No description provided for @tasbihUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo last count'**
  String get tasbihUndo;

  /// No description provided for @tasbihResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save this round to history and reset?'**
  String get tasbihResetConfirm;

  /// No description provided for @tasbihSessionLine.
  ///
  /// In en, this message translates to:
  /// **'Today: {count} counted'**
  String tasbihSessionLine(int count);

  /// No description provided for @tasbihTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached — may Allah accept'**
  String get tasbihTargetReached;

  /// No description provided for @ramadanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadanTitle;

  /// No description provided for @rozaDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String rozaDayOf(int day, int total);

  /// No description provided for @daysUntilRamadan.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day until Ramadan} other{{count} days until Ramadan}}'**
  String daysUntilRamadan(int count);

  /// No description provided for @monthTable.
  ///
  /// In en, this message translates to:
  /// **'Sahri & iftar this month'**
  String get monthTable;

  /// No description provided for @zakatTitle.
  ///
  /// In en, this message translates to:
  /// **'Zakat calculator'**
  String get zakatTitle;

  /// No description provided for @zakatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work out the zakat due on your wealth'**
  String get zakatSubtitle;

  /// No description provided for @zakatCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on hand'**
  String get zakatCash;

  /// No description provided for @zakatBank.
  ///
  /// In en, this message translates to:
  /// **'Bank balance'**
  String get zakatBank;

  /// No description provided for @zakatGold.
  ///
  /// In en, this message translates to:
  /// **'Gold (grams)'**
  String get zakatGold;

  /// No description provided for @zakatSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver (grams)'**
  String get zakatSilver;

  /// No description provided for @zakatBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business assets'**
  String get zakatBusiness;

  /// No description provided for @zakatInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get zakatInvestments;

  /// No description provided for @zakatOwed.
  ///
  /// In en, this message translates to:
  /// **'Money owed to you'**
  String get zakatOwed;

  /// No description provided for @zakatDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts (deducted)'**
  String get zakatDebts;

  /// No description provided for @zakatGoldPrice.
  ///
  /// In en, this message translates to:
  /// **'Gold price per gram'**
  String get zakatGoldPrice;

  /// No description provided for @zakatSilverPrice.
  ///
  /// In en, this message translates to:
  /// **'Silver price per gram'**
  String get zakatSilverPrice;

  /// No description provided for @zakatNeedPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter today\'s gold or silver price to work out the nisab.'**
  String get zakatNeedPrice;

  /// No description provided for @zakatInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get zakatInvalidNumber;

  /// No description provided for @zakatNeedMetalPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter the price for each metal you entered grams of.'**
  String get zakatNeedMetalPrice;

  /// No description provided for @zakatCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get zakatCalculate;

  /// No description provided for @zakatNisab.
  ///
  /// In en, this message translates to:
  /// **'Nisab threshold: {amount}'**
  String zakatNisab(String amount);

  /// No description provided for @zakatDue.
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {amount}'**
  String zakatDue(String amount);

  /// No description provided for @zakatNotPayable.
  ///
  /// In en, this message translates to:
  /// **'Your zakatable wealth is below the nisab — no zakat is due.'**
  String get zakatNotPayable;

  /// No description provided for @fitraInfo.
  ///
  /// In en, this message translates to:
  /// **'Sadaqat al-fitr is due per person before Eid prayer — roughly one sa\' (~2.5–3 kg) of staple food, or its value, per family member.'**
  String get fitraInfo;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @islamicDayName.
  ///
  /// In en, this message translates to:
  /// **'{day, select, hijriNewYear{Hijri New Year} ashura{Ashura} mawlid{Mawlid} israMiraj{Isra & Miraj} nisfShaban{Mid-Shaban} ramadanStart{Ramadan begins} laylatulQadr{Laylatul Qadr} eidAlFitr{Eid al-Fitr} arafah{Day of Arafah} eidAlAdha{Eid al-Adha} other{—}}'**
  String islamicDayName(String day);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A companion for the heart\'s daily deen'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times, qibla, Quran, dua, and gentle self-accounting — all offline, all yours.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingMadhabTitle.
  ///
  /// In en, this message translates to:
  /// **'Asr calculation'**
  String get onboardingMadhabTitle;

  /// No description provided for @onboardingMadhabNote.
  ///
  /// In en, this message translates to:
  /// **'This affects Asr time only — you can change it anytime in Settings.'**
  String get onboardingMadhabNote;

  /// No description provided for @onboardingMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get onboardingMethodTitle;

  /// No description provided for @onboardingMethodNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested for your region. You can change this later in Settings.'**
  String get onboardingMethodNote;

  /// No description provided for @onboardingNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay gently reminded'**
  String get onboardingNotifTitle;

  /// No description provided for @onboardingNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Azan at each waqt, sahri & iftar alerts, and an evening muhasaba nudge — all computed on your device.'**
  String get onboardingNotifBody;

  /// No description provided for @onboardingNotifDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can turn them on any time from Settings → Notifications.'**
  String get onboardingNotifDenied;

  /// No description provided for @onboardingNotifAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get onboardingNotifAllow;

  /// No description provided for @onboardingNotifSkip.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get onboardingNotifSkip;

  /// No description provided for @onboardingFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Bismillah'**
  String get onboardingFinishTitle;

  /// No description provided for @onboardingFinishBody.
  ///
  /// In en, this message translates to:
  /// **'Everything is ready. May your days be filled with light.'**
  String get onboardingFinishBody;

  /// No description provided for @onboardingBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get onboardingBegin;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @appLockEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get appLockEnterPin;

  /// No description provided for @appLockSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN'**
  String get appLockSetPin;

  /// No description provided for @appLockConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get appLockConfirmPin;

  /// No description provided for @appLockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs didn\'t match — try again'**
  String get appLockPinMismatch;

  /// No description provided for @appLockBiometricOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint or face?'**
  String get appLockBiometricOfferTitle;

  /// No description provided for @appLockBiometricOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Your PIN always works as a backup.'**
  String get appLockBiometricOfferBody;

  /// No description provided for @appLockBiometricUse.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get appLockBiometricUse;

  /// No description provided for @appLockBiometricSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get appLockBiometricSkip;

  /// No description provided for @appLockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN — try again'**
  String get appLockWrongPin;

  /// No description provided for @appLockUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint / face'**
  String get appLockUseBiometric;

  /// No description provided for @appLockEnable.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockEnable;

  /// No description provided for @appLockEnableSub.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN (and biometrics) to open Productive Muslim'**
  String get appLockEnableSub;

  /// No description provided for @appLockDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock'**
  String get appLockDisable;

  /// No description provided for @appLockDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get appLockDelete;

  /// No description provided for @appLockThrottled.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {time}.'**
  String appLockThrottled(String time);

  /// No description provided for @appLockForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get appLockForgotPin;

  /// No description provided for @appLockForgotReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to reset your app PIN'**
  String get appLockForgotReason;

  /// No description provided for @appLockNoDeviceLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reset the PIN here'**
  String get appLockNoDeviceLockTitle;

  /// No description provided for @appLockNoDeviceLockBody.
  ///
  /// In en, this message translates to:
  /// **'Your device has no screen lock, so we can\'t confirm it\'s you. Set up a screen lock in your device settings and try again. Clearing the app\'s data also removes the PIN, but erases your saved progress.'**
  String get appLockNoDeviceLockBody;

  /// No description provided for @appLockNewPin.
  ///
  /// In en, this message translates to:
  /// **'Set a new 4-digit PIN'**
  String get appLockNewPin;

  /// No description provided for @appLockPinProgress.
  ///
  /// In en, this message translates to:
  /// **'{entered} of 4 digits entered'**
  String appLockPinProgress(int entered);

  /// Screen-reader label for a stepper's increment button
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String a11yIncrease(String label);

  /// Screen-reader label for a stepper's decrement button
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String a11yDecrease(String label);

  /// No description provided for @prayerSheetWindow.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get prayerSheetWindow;

  /// No description provided for @prayerSheetRakaat.
  ///
  /// In en, this message translates to:
  /// **'Rakaat'**
  String get prayerSheetRakaat;

  /// No description provided for @rakaatFard.
  ///
  /// In en, this message translates to:
  /// **'Fard'**
  String get rakaatFard;

  /// No description provided for @rakaatSunnah.
  ///
  /// In en, this message translates to:
  /// **'Sunnah'**
  String get rakaatSunnah;

  /// No description provided for @rakaatWitr.
  ///
  /// In en, this message translates to:
  /// **'Witr'**
  String get rakaatWitr;

  /// No description provided for @prayerSheetNoJamaat.
  ///
  /// In en, this message translates to:
  /// **'No jamaat set'**
  String get prayerSheetNoJamaat;

  /// No description provided for @prayerFazilatFajr.
  ///
  /// In en, this message translates to:
  /// **'The two sunnah of Fajr are better than the world and all it contains. Its prayer is witnessed by the angels of night and day.'**
  String get prayerFazilatFajr;

  /// No description provided for @prayerFazilatDhuhr.
  ///
  /// In en, this message translates to:
  /// **'The gates of the heavens open at midday; the Prophet loved to pray four rakaat in that hour.'**
  String get prayerFazilatDhuhr;

  /// No description provided for @prayerFazilatAsr.
  ///
  /// In en, this message translates to:
  /// **'Guard the middle prayer. Whoever prays Asr will not enter the Fire before sunrise and before sunset.'**
  String get prayerFazilatAsr;

  /// No description provided for @prayerFazilatMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Pray it early, as soon as the sun has set. Two light rakaat of sunnah follow the fard.'**
  String get prayerFazilatMaghrib;

  /// No description provided for @prayerFazilatIsha.
  ///
  /// In en, this message translates to:
  /// **'Praying Isha in congregation is like standing half the night; joined with Fajr, like the whole night.'**
  String get prayerFazilatIsha;

  /// No description provided for @dailyKindAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get dailyKindAyah;

  /// No description provided for @dailyAyahTitle.
  ///
  /// In en, this message translates to:
  /// **'Ayah of the day'**
  String get dailyAyahTitle;

  /// No description provided for @duaOfDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Dua of the day'**
  String get duaOfDayTitle;

  /// No description provided for @dailyAyahReference.
  ///
  /// In en, this message translates to:
  /// **'{surah}, ayah {ayah}'**
  String dailyAyahReference(String surah, String ayah);

  /// No description provided for @tasbihQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihQuickTitle;

  /// No description provided for @tasbihQuickHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get tasbihQuickHint;

  /// No description provided for @qiblaChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaChipLabel;

  /// No description provided for @qiblaChipNeedsLocation.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get qiblaChipNeedsLocation;

  /// No description provided for @dayTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s timeline'**
  String get dayTimelineTitle;

  /// No description provided for @streakMilestone.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak! 🎉'**
  String streakMilestone(int count);

  /// No description provided for @calculatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get calculatorsTitle;

  /// No description provided for @calculatorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zakat, fitra, qaza, inheritance & age'**
  String get calculatorsSubtitle;

  /// No description provided for @fitraTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitra calculator'**
  String get fitraTitle;

  /// No description provided for @fitraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate Sadaqatul Fitr for your household'**
  String get fitraSubtitle;

  /// No description provided for @fitraStaple.
  ///
  /// In en, this message translates to:
  /// **'Staple food'**
  String get fitraStaple;

  /// No description provided for @fitraStapleWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat / flour'**
  String get fitraStapleWheat;

  /// No description provided for @fitraStapleBarley.
  ///
  /// In en, this message translates to:
  /// **'Barley'**
  String get fitraStapleBarley;

  /// No description provided for @fitraStapleDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get fitraStapleDates;

  /// No description provided for @fitraStapleRaisins.
  ///
  /// In en, this message translates to:
  /// **'Raisins'**
  String get fitraStapleRaisins;

  /// No description provided for @fitraPricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get fitraPricePerKg;

  /// No description provided for @fitraPeople.
  ///
  /// In en, this message translates to:
  /// **'Number of people'**
  String get fitraPeople;

  /// No description provided for @fitraCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get fitraCalculate;

  /// No description provided for @fitraPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person: {amount}'**
  String fitraPerPerson(String amount);

  /// No description provided for @fitraTotal.
  ///
  /// In en, this message translates to:
  /// **'Total fitra: {amount}'**
  String fitraTotal(String amount);

  /// No description provided for @fitraWeightNote.
  ///
  /// In en, this message translates to:
  /// **'Based on {kg} kg per person'**
  String fitraWeightNote(String kg);

  /// No description provided for @fitraBeforeEid.
  ///
  /// In en, this message translates to:
  /// **'Pay before the Eid prayer.'**
  String get fitraBeforeEid;

  /// No description provided for @qazaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qaza prayer calculator'**
  String get qazaTitle;

  /// No description provided for @qazaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate missed obligatory prayers to make up'**
  String get qazaSubtitle;

  /// No description provided for @qazaStartDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get qazaStartDate;

  /// No description provided for @qazaEndDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get qazaEndDate;

  /// No description provided for @qazaSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get qazaSelectDate;

  /// No description provided for @qazaIncludeWitr.
  ///
  /// In en, this message translates to:
  /// **'Include Witr (Hanafi)'**
  String get qazaIncludeWitr;

  /// No description provided for @qazaAlreadyMadeUp.
  ///
  /// In en, this message translates to:
  /// **'Already made up (per prayer)'**
  String get qazaAlreadyMadeUp;

  /// No description provided for @qazaEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start date.'**
  String get qazaEndBeforeStart;

  /// No description provided for @qazaCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get qazaCalculate;

  /// No description provided for @qazaDays.
  ///
  /// In en, this message translates to:
  /// **'Period: {count} days'**
  String qazaDays(String count);

  /// No description provided for @qazaPerPrayer.
  ///
  /// In en, this message translates to:
  /// **'Each prayer: {count}'**
  String qazaPerPrayer(String count);

  /// No description provided for @qazaWitr.
  ///
  /// In en, this message translates to:
  /// **'Witr: {count}'**
  String qazaWitr(String count);

  /// No description provided for @qazaTotal.
  ///
  /// In en, this message translates to:
  /// **'Total missed: {count}'**
  String qazaTotal(String count);

  /// No description provided for @qazaNote.
  ///
  /// In en, this message translates to:
  /// **'An estimate to help you plan — make them up steadily, without guilt.'**
  String get qazaNote;

  /// No description provided for @ageTitle.
  ///
  /// In en, this message translates to:
  /// **'Age calculator'**
  String get ageTitle;

  /// No description provided for @ageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your age in both the Gregorian and Hijri calendars'**
  String get ageSubtitle;

  /// No description provided for @ageBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get ageBirthDate;

  /// No description provided for @ageAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of date'**
  String get ageAsOf;

  /// No description provided for @ageSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get ageSelectDate;

  /// No description provided for @ageCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get ageCalculate;

  /// No description provided for @ageGregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian age'**
  String get ageGregorian;

  /// No description provided for @ageHijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri age'**
  String get ageHijri;

  /// No description provided for @ageValue.
  ///
  /// In en, this message translates to:
  /// **'{years} years, {months} months, {days} days'**
  String ageValue(String years, String months, String days);

  /// No description provided for @ageTotalDays.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} days'**
  String ageTotalDays(String count);

  /// No description provided for @faraidTitle.
  ///
  /// In en, this message translates to:
  /// **'Inheritance calculator'**
  String get faraidTitle;

  /// No description provided for @faraidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate shares for common heirs (Faraid)'**
  String get faraidSubtitle;

  /// No description provided for @faraidEstate.
  ///
  /// In en, this message translates to:
  /// **'Estate value'**
  String get faraidEstate;

  /// No description provided for @faraidSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get faraidSpouse;

  /// No description provided for @faraidNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get faraidNone;

  /// No description provided for @faraidHusband.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get faraidHusband;

  /// No description provided for @faraidWife.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get faraidWife;

  /// No description provided for @faraidWives.
  ///
  /// In en, this message translates to:
  /// **'Number of wives'**
  String get faraidWives;

  /// No description provided for @faraidFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get faraidFather;

  /// No description provided for @faraidMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get faraidMother;

  /// No description provided for @faraidSons.
  ///
  /// In en, this message translates to:
  /// **'Sons'**
  String get faraidSons;

  /// No description provided for @faraidDaughters.
  ///
  /// In en, this message translates to:
  /// **'Daughters'**
  String get faraidDaughters;

  /// No description provided for @faraidBrothers.
  ///
  /// In en, this message translates to:
  /// **'Full brothers'**
  String get faraidBrothers;

  /// No description provided for @faraidSisters.
  ///
  /// In en, this message translates to:
  /// **'Full sisters'**
  String get faraidSisters;

  /// No description provided for @faraidCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get faraidCalculate;

  /// No description provided for @faraidShare.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}'**
  String faraidShare(String label, String amount);

  /// No description provided for @faraidAwlNote.
  ///
  /// In en, this message translates to:
  /// **'Shares exceed the estate — reduced proportionally (\'Awl).'**
  String get faraidAwlNote;

  /// No description provided for @faraidRaddNote.
  ///
  /// In en, this message translates to:
  /// **'Surplus returned to the heirs (Radd).'**
  String get faraidRaddNote;

  /// No description provided for @faraidUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Unallocated (to other relatives): {amount}'**
  String faraidUnallocated(String amount);

  /// No description provided for @faraidDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'An estimate for common heirs only. Consult a qualified scholar for a binding ruling.'**
  String get faraidDisclaimer;

  /// No description provided for @faraidHeirHusband.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get faraidHeirHusband;

  /// No description provided for @faraidHeirWife.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get faraidHeirWife;

  /// No description provided for @faraidHeirFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get faraidHeirFather;

  /// No description provided for @faraidHeirMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get faraidHeirMother;

  /// No description provided for @faraidHeirSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get faraidHeirSon;

  /// No description provided for @faraidHeirDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get faraidHeirDaughter;

  /// No description provided for @faraidHeirBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get faraidHeirBrother;

  /// No description provided for @faraidHeirSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get faraidHeirSister;

  /// No description provided for @hadithOfDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith of the day'**
  String get hadithOfDayTitle;

  /// No description provided for @hadithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadithTitle;

  /// No description provided for @hadithNotFound.
  ///
  /// In en, this message translates to:
  /// **'This hadith isn\'t available.'**
  String get hadithNotFound;

  /// No description provided for @hadithSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authentic narrations to reflect on'**
  String get hadithSubtitle;

  /// No description provided for @hadithNarratedBy.
  ///
  /// In en, this message translates to:
  /// **'Narrated by {narrator}'**
  String hadithNarratedBy(String narrator);

  /// No description provided for @hadithTopicName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, intention{Intention & sincerity} faith{Faith} character{Character & manners} speech{Speech & the tongue} knowledge{Seeking knowledge} charity{Charity & kindness} mercy{Mercy & humility} worship{Worship} dunya{This world & the hereafter} other{Other}}'**
  String hadithTopicName(String id);

  /// No description provided for @hadithCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hadith} other{{count} hadith}}'**
  String hadithCount(int count);

  /// No description provided for @hadithChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String hadithChapterCount(int count);

  /// No description provided for @hadithBooksCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Full collections'**
  String get hadithBooksCardTitle;

  /// No description provided for @hadithBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith collections'**
  String get hadithBooksTitle;

  /// No description provided for @hadithBooksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse the full books, fetched from an open dataset'**
  String get hadithBooksSubtitle;

  /// No description provided for @hadithBookAllSahih.
  ///
  /// In en, this message translates to:
  /// **'Every hadith authentic (Sahih)'**
  String get hadithBookAllSahih;

  /// No description provided for @hadithGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade: {grade}'**
  String hadithGradeLabel(String grade);

  /// No description provided for @hadithLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load. Check your connection and try again.'**
  String get hadithLoadError;

  /// No description provided for @hadithRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hadithRetry;

  /// No description provided for @hadithSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Source: fawazahmed0/hadith-api (public domain)'**
  String get hadithSourceNote;

  /// No description provided for @hadithSourceNoteBn.
  ///
  /// In en, this message translates to:
  /// **'Bengali source: hadithbangla (open source)'**
  String get hadithSourceNoteBn;

  /// No description provided for @hadithEnglishOnly.
  ///
  /// In en, this message translates to:
  /// **'English only'**
  String get hadithEnglishOnly;

  /// No description provided for @hadithBengaliUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No Bengali translation — showing English'**
  String get hadithBengaliUnavailable;

  /// No description provided for @hadithBengaliUnavailableSection.
  ///
  /// In en, this message translates to:
  /// **'Bengali isn\'t available for this book yet — showing English.'**
  String get hadithBengaliUnavailableSection;

  /// No description provided for @duaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search duas'**
  String get duaSearchHint;

  /// No description provided for @duaSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get duaSearchTitle;

  /// No description provided for @duaNoResults.
  ///
  /// In en, this message translates to:
  /// **'No duas found'**
  String get duaNoResults;

  /// No description provided for @duaFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get duaFavoritesTitle;

  /// No description provided for @duaFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any dua to save it here'**
  String get duaFavoritesEmpty;

  /// No description provided for @favoriteAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteAddLabel;

  /// No description provided for @favoriteRemoveLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favoriteRemoveLabel;

  /// No description provided for @widgetNextPrayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get widgetNextPrayerLabel;

  /// No description provided for @nearbyMosquesLabel.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get nearbyMosquesLabel;

  /// No description provided for @nearbyMosquesLaunchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Maps. Make sure a maps app is installed.'**
  String get nearbyMosquesLaunchError;

  /// No description provided for @nearbyMosquesLocationError.
  ///
  /// In en, this message translates to:
  /// **'Set your location first to find nearby mosques.'**
  String get nearbyMosquesLocationError;

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense tracker'**
  String get expenseTitle;

  /// No description provided for @expenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly hisab, no israf'**
  String get expenseSubtitle;

  /// No description provided for @expenseAdd.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseAdd;

  /// No description provided for @expenseSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get expenseSave;

  /// No description provided for @expenseAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmountHint;

  /// No description provided for @expenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get expenseNoteHint;

  /// No description provided for @expenseMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get expenseMonthTotal;

  /// No description provided for @expensePrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get expensePrevMonth;

  /// No description provided for @expenseNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get expenseNextMonth;

  /// No description provided for @expenseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses logged.'**
  String get expenseEmpty;

  /// No description provided for @expenseIsrafReminder.
  ///
  /// In en, this message translates to:
  /// **'“And those who, when they spend, are neither extravagant nor stingy, but hold a just balance between them.” (Al-Furqan 25:67)'**
  String get expenseIsrafReminder;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'{id, select, need{Needs} family{Family} sadaqah{Sadaqah} want{Wants} other{{id}}}'**
  String expenseCategory(String id);

  /// No description provided for @expenseEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get expenseEdit;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @expenseUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get expenseUndo;

  /// No description provided for @expenseSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get expenseSaveFailed;

  /// No description provided for @expenseAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole amount'**
  String get expenseAmountInvalid;

  /// No description provided for @expenseBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get expenseBudget;

  /// No description provided for @expenseBudgetClear.
  ///
  /// In en, this message translates to:
  /// **'Remove budget'**
  String get expenseBudgetClear;

  /// No description provided for @expenseBudgetLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} left of {budget}'**
  String expenseBudgetLeft(String left, String budget);

  /// No description provided for @expenseBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over budget — rethink the wants'**
  String expenseBudgetOver(String amount);

  /// No description provided for @expenseVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{dir, select, more{{amount} more than last month} less{{amount} less than last month} other{Same as last month}}'**
  String expenseVsLastMonth(String dir, String amount);

  /// No description provided for @expenseVsLastMonthSoFar.
  ///
  /// In en, this message translates to:
  /// **'{dir, select, more{{amount} more than this time last month} less{{amount} less than this time last month} other{Same as this time last month}}'**
  String expenseVsLastMonthSoFar(String dir, String amount);

  /// No description provided for @expenseYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get expenseYesterday;

  /// No description provided for @expenseCategoryBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a category to filter; hold to set its budget (sadaqah: a goal)'**
  String get expenseCategoryBudgetHint;

  /// No description provided for @expenseCategoryBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'{id, select, need{Needs budget} family{Family budget} sadaqah{Monthly sadaqah goal} want{Wants budget} other{{id}}}'**
  String expenseCategoryBudgetTitle(String id);

  /// No description provided for @expenseBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get expenseBackup;

  /// No description provided for @expenseExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy CSV backup'**
  String get expenseExportCsv;

  /// No description provided for @expenseImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Restore from copied CSV'**
  String get expenseImportCsv;

  /// No description provided for @expenseExported.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it into Notes, email or a spreadsheet to keep it safe.'**
  String get expenseExported;

  /// No description provided for @expenseImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'The clipboard doesn\'t hold an expense backup.'**
  String get expenseImportInvalid;

  /// No description provided for @expenseImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing new to restore} =1{1 expense restored} other{{count} expenses restored}}'**
  String expenseImported(int count);

  /// No description provided for @hadithSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search hadith'**
  String get hadithSearchHint;

  /// No description provided for @hadithNoResults.
  ///
  /// In en, this message translates to:
  /// **'No hadith found'**
  String get hadithNoResults;

  /// No description provided for @ruqyahSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search ruqyah'**
  String get ruqyahSearchHint;

  /// No description provided for @ruqyahNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get ruqyahNoResults;

  /// No description provided for @scheduleRuleRemoved.
  ///
  /// In en, this message translates to:
  /// **'Schedule rule removed'**
  String get scheduleRuleRemoved;

  /// No description provided for @countdownSeeDay.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get countdownSeeDay;

  /// No description provided for @settingHomeCards.
  ///
  /// In en, this message translates to:
  /// **'Home cards'**
  String get settingHomeCards;

  /// No description provided for @settingHomeCardsSub.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections appear on Home'**
  String get settingHomeCardsSub;

  /// No description provided for @homeCardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeCardQuickActions;

  /// No description provided for @homeCardDaily.
  ///
  /// In en, this message translates to:
  /// **'Ayah, hadith & dua of the day'**
  String get homeCardDaily;

  /// No description provided for @focusHeader.
  ///
  /// In en, this message translates to:
  /// **'Jamaat focus'**
  String get focusHeader;

  /// No description provided for @focusToggle.
  ///
  /// In en, this message translates to:
  /// **'Silent & lock at jamaat'**
  String get focusToggle;

  /// No description provided for @focusToggleSub.
  ///
  /// In en, this message translates to:
  /// **'Silences the phone and blocks other apps around jamaat. Needs jamaat times in My Mosque'**
  String get focusToggleSub;

  /// No description provided for @focusToggleSubIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone doesn\'t let apps silence or lock the phone, so you\'ll get a reminder to switch to silent. Needs jamaat times in My Mosque'**
  String get focusToggleSubIos;

  /// No description provided for @focusLeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts before jamaat'**
  String get focusLeadLabel;

  /// No description provided for @focusDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlocks after'**
  String get focusDurationLabel;

  /// No description provided for @focusDurationManual.
  ///
  /// In en, this message translates to:
  /// **'When I end it'**
  String get focusDurationManual;

  /// No description provided for @focusPrayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get focusPrayersLabel;

  /// No description provided for @focusBlockToggle.
  ///
  /// In en, this message translates to:
  /// **'Lock the phone'**
  String get focusBlockToggle;

  /// No description provided for @focusBlockToggleSub.
  ///
  /// In en, this message translates to:
  /// **'Other apps are blocked; phone calls stay allowed'**
  String get focusBlockToggleSub;

  /// No description provided for @focusStrictToggle.
  ///
  /// In en, this message translates to:
  /// **'Strict mode'**
  String get focusStrictToggle;

  /// No description provided for @focusStrictToggleSub.
  ///
  /// In en, this message translates to:
  /// **'No early unlock, and these settings stay locked while a session runs'**
  String get focusStrictToggleSub;

  /// No description provided for @focusPermSilence.
  ///
  /// In en, this message translates to:
  /// **'Allow Do Not Disturb access to silence the phone'**
  String get focusPermSilence;

  /// No description provided for @focusPermBlock.
  ///
  /// In en, this message translates to:
  /// **'Allow accessibility access to lock the phone'**
  String get focusPermBlock;

  /// No description provided for @focusAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get focusAllow;

  /// No description provided for @focusDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access'**
  String get focusDisclosureTitle;

  /// No description provided for @focusDisclosureBody.
  ///
  /// In en, this message translates to:
  /// **'Productive Muslim uses the Accessibility service only during a jamaat focus session: to notice when another app opens and cover it with the jamaat screen. It does not read, collect or share anything you see or type.'**
  String get focusDisclosureBody;

  /// No description provided for @focusContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get focusContinue;

  /// No description provided for @focusActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Jamaat focus is on until {time}'**
  String focusActiveUntil(String time);

  /// No description provided for @focusActive.
  ///
  /// In en, this message translates to:
  /// **'Jamaat focus is on'**
  String get focusActive;

  /// No description provided for @focusStrictLocked.
  ///
  /// In en, this message translates to:
  /// **'Strict mode — settings unlock when the session ends.'**
  String get focusStrictLocked;

  /// No description provided for @focusEndNow.
  ///
  /// In en, this message translates to:
  /// **'End now'**
  String get focusEndNow;

  /// No description provided for @notifFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} jamaat — time to focus'**
  String notifFocusTitle(String prayer);

  /// No description provided for @notifFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Put your phone on silent and head to salah.'**
  String get notifFocusBody;

  /// No description provided for @focusLockBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone is silenced for jamaat.'**
  String get focusLockBody;

  /// No description provided for @focusLockBodyUntil.
  ///
  /// In en, this message translates to:
  /// **'Silenced for jamaat until {time}'**
  String focusLockBodyUntil(String time);

  /// No description provided for @focusEndAction.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get focusEndAction;

  /// No description provided for @channelFocus.
  ///
  /// In en, this message translates to:
  /// **'Jamaat focus'**
  String get channelFocus;

  /// No description provided for @shortcutsGuideRow.
  ///
  /// In en, this message translates to:
  /// **'Auto-silent with Shortcuts'**
  String get shortcutsGuideRow;

  /// No description provided for @shortcutsGuideRowSub.
  ///
  /// In en, this message translates to:
  /// **'Set up your iPhone to silence itself at the mosque'**
  String get shortcutsGuideRowSub;

  /// No description provided for @shortcutsGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-silent on iPhone'**
  String get shortcutsGuideTitle;

  /// No description provided for @shortcutsGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'The Shortcuts app can turn on Do Not Disturb for you. Set it up once:'**
  String get shortcutsGuideIntro;

  /// No description provided for @shortcutsMosqueHeader.
  ///
  /// In en, this message translates to:
  /// **'When you reach the mosque (recommended)'**
  String get shortcutsMosqueHeader;

  /// No description provided for @shortcutsMosqueStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Shortcuts → Automation → + (New Automation).'**
  String get shortcutsMosqueStep1;

  /// No description provided for @shortcutsMosqueStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose Arrive, pick your mosque\'s location, select Run Immediately, then tap Next.'**
  String get shortcutsMosqueStep2;

  /// No description provided for @shortcutsMosqueStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap New Blank Automation → Add Action, and search for “Set Focus”.'**
  String get shortcutsMosqueStep3;

  /// No description provided for @shortcutsMosqueStep4.
  ///
  /// In en, this message translates to:
  /// **'Set it to: Turn Do Not Disturb On until I Leave. Tap Done.'**
  String get shortcutsMosqueStep4;

  /// No description provided for @shortcutsTimeHeader.
  ///
  /// In en, this message translates to:
  /// **'At a fixed jamaat time'**
  String get shortcutsTimeHeader;

  /// No description provided for @shortcutsTimeStep1.
  ///
  /// In en, this message translates to:
  /// **'Automation → + → Time of Day. Pick a few minutes before jamaat, Daily, Run Immediately.'**
  String get shortcutsTimeStep1;

  /// No description provided for @shortcutsTimeStep2.
  ///
  /// In en, this message translates to:
  /// **'Add the “Set Focus” action: Turn Do Not Disturb On until a time after jamaat.'**
  String get shortcutsTimeStep2;

  /// No description provided for @shortcutsTimeStep3.
  ///
  /// In en, this message translates to:
  /// **'Make one automation for each prayer.'**
  String get shortcutsTimeStep3;

  /// No description provided for @shortcutsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Shortcuts'**
  String get shortcutsOpen;

  /// No description provided for @notifFocusEndTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} — prayed in jamaat?'**
  String notifFocusEndTitle(String prayer);

  /// No description provided for @notifFocusEndBody.
  ///
  /// In en, this message translates to:
  /// **'Mark it in Muhasaba, then tap for the after-salah adhkar.'**
  String get notifFocusEndBody;

  /// No description provided for @prayerTimesComputeFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t calculate prayer times'**
  String get prayerTimesComputeFailedTitle;

  /// No description provided for @prayerTimesComputeFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times can\'t be worked out for this location with the current settings. Try another location or calculation method.'**
  String get prayerTimesComputeFailedBody;

  /// No description provided for @prayerTimesExactAlarmBanner.
  ///
  /// In en, this message translates to:
  /// **'Azan may arrive late. Tap to allow exact alarms.'**
  String get prayerTimesExactAlarmBanner;

  /// No description provided for @qiblaCompassPoint.
  ///
  /// In en, this message translates to:
  /// **'{point, select, N{N} NNE{NNE} NE{NE} ENE{ENE} E{E} ESE{ESE} SE{SE} SSE{SSE} S{S} SSW{SSW} SW{SW} WSW{WSW} W{W} WNW{WNW} NW{NW} NNW{NNW} other{{point}}}'**
  String qiblaCompassPoint(String point);

  /// Reason shown in the OS biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Unlock Productive Muslim'**
  String get appLockBiometricReason;

  /// Screen-reader label for the onboarding progress bar
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepProgress(int step, int total);

  /// No description provided for @editorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get editorDiscardTitle;

  /// No description provided for @editorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editorDiscard;

  /// No description provided for @muhasabaIconOption.
  ///
  /// In en, this message translates to:
  /// **'Icon {n}'**
  String muhasabaIconOption(int n);

  /// No description provided for @muhasabaColorOption.
  ///
  /// In en, this message translates to:
  /// **'Color {n}'**
  String muhasabaColorOption(int n);

  /// No description provided for @tasbihTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 99999'**
  String get tasbihTargetInvalid;

  /// No description provided for @hadithTopicsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the hadith. Please try again.'**
  String get hadithTopicsLoadError;

  /// No description provided for @ruqyahLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load ruqyah. Please try again.'**
  String get ruqyahLoadError;

  /// No description provided for @duaLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the duas. Please try again.'**
  String get duaLoadError;

  /// No description provided for @hadithSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hadith in this chapter.'**
  String get hadithSectionEmpty;

  /// One word of an English-source hadith grade; other{—} means pass the word through unchanged.
  ///
  /// In en, this message translates to:
  /// **'{word, select, sahih{Sahih} hasan{Hasan} daif{Da\'if} very{Very} isnaad{Isnaad} mauquf{Mauquf} muquf{Mauquf} maqtu{Maqtu} lighairihi{li-Ghayrihi} hadith{Hadith} shadh{Shadh} munkar{Munkar} mawdu{Mawdu} mutawatir{Mutawatir} other{—}}'**
  String hadithGradeWord(String word);

  /// No description provided for @fastingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get fastingSaveFailed;

  /// No description provided for @faraidOtherRelatives.
  ///
  /// In en, this message translates to:
  /// **'Any grandchild, grandparent, half-sibling, paternal uncle, nephew or cousin?'**
  String get faraidOtherRelatives;

  /// No description provided for @faraidOutOfScope.
  ///
  /// In en, this message translates to:
  /// **'These relatives can change every share, and this calculator doesn\'t cover them. Please ask a qualified scholar for this distribution.'**
  String get faraidOutOfScope;

  /// No description provided for @faraidUmariyyataynNote.
  ///
  /// In en, this message translates to:
  /// **'Special case (\'Umariyyatayn): the mother takes one third of what remains after the spouse\'s share; the father takes the rest.'**
  String get faraidUmariyyataynNote;

  /// No description provided for @faraidUnallocatedNote.
  ///
  /// In en, this message translates to:
  /// **'None of the heirs entered takes the remainder. It may go to more distant relatives — ask a scholar how your school assigns it.'**
  String get faraidUnallocatedNote;

  /// No description provided for @faraidBasisTwoThirdsShared.
  ///
  /// In en, this message translates to:
  /// **'2/3 (shared)'**
  String get faraidBasisTwoThirdsShared;

  /// No description provided for @faraidBasisThirdOfResidue.
  ///
  /// In en, this message translates to:
  /// **'1/3 of the remainder'**
  String get faraidBasisThirdOfResidue;

  /// No description provided for @faraidBasisResiduary.
  ///
  /// In en, this message translates to:
  /// **'residuary (\'asaba)'**
  String get faraidBasisResiduary;

  /// No description provided for @faraidBasisSixthPlusResiduary.
  ///
  /// In en, this message translates to:
  /// **'1/6 + residuary'**
  String get faraidBasisSixthPlusResiduary;

  /// No description provided for @faraidBasisResiduaryTwoToOne.
  ///
  /// In en, this message translates to:
  /// **'residuary (2:1)'**
  String get faraidBasisResiduaryTwoToOne;

  /// No description provided for @faraidInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get faraidInvalidNumber;

  /// No description provided for @fitraInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get fitraInvalidNumber;

  /// No description provided for @qazaInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get qazaInvalidNumber;

  /// No description provided for @mosqueRenameProfile.
  ///
  /// In en, this message translates to:
  /// **'Rename mosque'**
  String get mosqueRenameProfile;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked for this app. Allow it in Settings, or pick your city below.'**
  String get locationDeniedForever;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again, or pick your city below.'**
  String get locationUnavailable;

  /// No description provided for @locationRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get locationRetry;
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
