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
