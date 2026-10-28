// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'প্রোডাক্টিভ মুসলিম';

  @override
  String get tabHome => 'হোম';

  @override
  String get tabQuran => 'কুরআন';

  @override
  String get tabMuhasaba => 'মুহাসাবা';

  @override
  String get tabDua => 'দুআ';

  @override
  String get tabMore => 'আরও';

  @override
  String get comingSoon => 'শীঘ্রই আসছে';

  @override
  String get galleryTitle => 'উইজেট গ্যালারি';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get groupCalculation => 'নামাজের হিসাব';

  @override
  String get moreGroupWorship => 'ইবাদত';

  @override
  String get moreGroupTools => 'টুলস';

  @override
  String get moreGroupYou => 'আপনি';

  @override
  String get groupNotifications => 'নোটিফিকেশন';

  @override
  String get groupAppearance => 'থিম ও ভাষা';

  @override
  String get groupPrivacy => 'প্রাইভেসি';

  @override
  String get groupAbout => 'অ্যাপ সম্পর্কে';

  @override
  String get settingLocation => 'অবস্থান';

  @override
  String get settingLocationNotSet => 'নির্ধারণ করা হয়নি';

  @override
  String get settingMadhab => 'মাযহাব (আসর)';

  @override
  String get settingMethod => 'হিসাবের পদ্ধতি';

  @override
  String get settingAdjustments => 'মিনিট সমন্বয়';

  @override
  String get settingAdjustmentsSub => 'প্রতিটি ওয়াক্ত ±মিনিট ঠিক করুন';

  @override
  String get settingHighLat => 'উচ্চ-অক্ষাংশ নিয়ম';

  @override
  String get settingHighLatSub => 'অ্যাডভান্সড — চরম অক্ষাংশের জন্য';

  @override
  String get settingHijriOffset => 'হিজরি তারিখ সমন্বয়';

  @override
  String get settingHijriOffsetSub => 'আপনার এলাকার চাঁদ দেখার সাথে মেলান';

  @override
  String hijriOffsetValue(int count, String sign) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sign$countString দিন',
    );
    return '$_temp0';
  }

  @override
  String get settingSahriSafety => 'সাহরির সতর্কতা সময়';

  @override
  String get settingSahriSafetySub => 'ফজরের এত মিনিট আগে সাহরি শেষ করুন';

  @override
  String get settingTheme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get settingLanguage => 'ভাষা';

  @override
  String get settingAppLock => 'অ্যাপ লক';

  @override
  String get settingRunSetup => 'আবার সেটআপ চালান';

  @override
  String get settingShowAchievements => 'অর্জন দেখান';

  @override
  String get settingShowAchievementsSub =>
      'মুহাসাবায় ব্যাজ ও ধারাবাহিকতার মাইলফলক';

  @override
  String get settingHaptics => 'হ্যাপটিক ফিডব্যাক';

  @override
  String get settingHapticsSub => 'ট্যাপ ও তাসবিহ গণনায় ভাইব্রেশন';

  @override
  String get settingCredits => 'কৃতজ্ঞতা ও স্বীকৃতি';

  @override
  String get creditsBody =>
      'নামাজের সময় ডিভাইসেই হিসাব করা হয়। শহরের ডেটাবেস © GeoNames (CC BY 4.0)। ফন্ট: Schibsted Grotesk, Noto Sans Bengali, IBM Plex Sans Arabic (OFL), KFGQPC Uthmanic Script HAFS © কিং ফাহদ গ্লোরিয়াস কুরআন প্রিন্টিং কমপ্লেক্স।';

  @override
  String get madhabHanafi => 'হানাফি';

  @override
  String get madhabShafi => 'শাফেয়ি';

  @override
  String get madhabMaliki => 'মালিকি';

  @override
  String get madhabHanbali => 'হাম্বলি';

  @override
  String get madhabExplain => 'শুধু আসরের সময়ে প্রভাব ফেলে';

  @override
  String get highLatMiddle => 'মধ্যরাত্রি পদ্ধতি';

  @override
  String get highLatSeventh => 'রাতের এক-সপ্তমাংশ';

  @override
  String get highLatTwilight => 'গোধূলি কোণ';

  @override
  String get methodMuslimWorldLeague => 'মুসলিম ওয়ার্ল্ড লীগ';

  @override
  String get methodEgyptian => 'মিশরীয় জেনারেল অথরিটি';

  @override
  String get methodKarachi => 'ইসলামিক সায়েন্সেস বিশ্ববিদ্যালয়, করাচি';

  @override
  String get methodUmmAlQura => 'উম্মুল কুরা (মক্কা)';

  @override
  String get methodDubai => 'দুবাই';

  @override
  String get methodQatar => 'কাতার';

  @override
  String get methodKuwait => 'কুয়েত';

  @override
  String get methodMoonsighting => 'মুনসাইটিং কমিটি';

  @override
  String get methodSingapore => 'সিঙ্গাপুর (MUIS)';

  @override
  String get methodNorthAmerica => 'ISNA (উত্তর আমেরিকা)';

  @override
  String get methodTurkiye => 'তুরস্ক (দিয়ানেত)';

  @override
  String get methodTehran => 'তেহরান (IGUT)';

  @override
  String get prayerFajr => 'ফজর';

  @override
  String get prayerDhuhr => 'যোহর';

  @override
  String get prayerAsr => 'আসর';

  @override
  String get prayerMaghrib => 'মাগরিব';

  @override
  String get prayerIsha => 'এশা';

  @override
  String get locationTitle => 'অবস্থান';

  @override
  String get locationUseGps => 'আমার অবস্থান ব্যবহার করুন';

  @override
  String get locationUseGpsSub =>
      'GPS — প্রথমবারের পর সম্পূর্ণ অফলাইনে কাজ করে';

  @override
  String get locationChooseCity => 'শহর নিজে বেছে নিন';

  @override
  String get openSystemSettings => 'সেটিংস খুলুন';

  @override
  String get locationSearchError => 'শহর খোঁজা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get locationSearchHint => 'শহর খুঁজুন…';

  @override
  String get locationPrimingBody =>
      'প্রোডাক্টিভ মুসলিম আপনার অবস্থান এই ডিভাইসেই নামাজের সময় ও কিবলার দিক হিসাবের জন্য ব্যবহার করে। আপনি নিজে ম্যাপে কাছের মসজিদ খুললে তবেই তা শেয়ার হয়।';

  @override
  String get locationDeniedFallback =>
      'সমস্যা নেই — নিচে আপনার শহর বেছে নিন, সবকিছু একইভাবে কাজ করবে।';

  @override
  String get locationServiceOff =>
      'লোকেশন সার্ভিস বন্ধ আছে। নিচে শহর বেছে নিন, অথবা লোকেশন চালু করে আবার চেষ্টা করুন।';

  @override
  String get locationCurrent => 'বর্তমান অবস্থান';

  @override
  String get searchNoResults => 'কোনো শহর মেলেনি — অন্য বানানে চেষ্টা করুন';

  @override
  String minutesShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString মিনিট';
  }

  @override
  String countdownStartsIn(String prayer) {
    return '$prayer শুরু হতে বাকি';
  }

  @override
  String get countdownJamaatIn => 'জামাত শুরু হতে বাকি';

  @override
  String countdownEndsIn(String prayer) {
    return '$prayer শেষ হতে বাকি';
  }

  @override
  String get countdownSahriEnds => 'সাহরি শেষ হতে বাকি';

  @override
  String get countdownIftarIn => 'ইফতারের বাকি';

  @override
  String subAt(String label, String time) {
    return '$label $time এ';
  }

  @override
  String get jamaatLabel => 'জামাত';

  @override
  String get sunriseLabel => 'সূর্যোদয়';

  @override
  String get sunsetLabel => 'সূর্যাস্ত';

  @override
  String get sahriEndsLabel => 'সাহরি শেষ';

  @override
  String get iftarLabel => 'ইফতার';

  @override
  String get greetingMorning => 'শুভ সকাল';

  @override
  String get greetingAfternoon => 'শুভ দুপুর';

  @override
  String get greetingEvening => 'শুভ সন্ধ্যা';

  @override
  String get greetingNight => 'শুভ রাত্রি';

  @override
  String continueReadingAyah(String number) {
    return 'আয়াত $number';
  }

  @override
  String get forbiddenTimesTitle => 'নিষিদ্ধ ওয়াক্ত';

  @override
  String get naflTimesTitle => 'নফল সালাত';

  @override
  String get specialNow => 'এখন';

  @override
  String get specialTimeForbiddenSunrise => 'সূর্যোদয়ের পর';

  @override
  String get specialTimeForbiddenZawal => 'দ্বিপ্রহর (যাওয়াল)';

  @override
  String get specialTimeForbiddenSunset => 'সূর্যাস্তের আগে';

  @override
  String get specialTimeIshraq => 'ইশরাক';

  @override
  String get specialTimeDuha => 'চাশত (দুহা)';

  @override
  String get specialTimeSalatZawal => 'সালাতুয যাওয়াল';

  @override
  String get specialTimeAwwabin => 'আওয়াবিন';

  @override
  String get specialTimeTahajjud => 'তাহাজ্জুদ';

  @override
  String get forbiddenTimesSubtitle =>
      'এই তিন সময়ে কোনো সালাত আদায় করা যায় না।';

  @override
  String get naflTimesSubtitle => 'নফল সালাত আদায়ের উত্তম সময়।';

  @override
  String get specialTimesLearnMore => 'বিস্তারিত দেখতে চাপুন';

  @override
  String get specialTimesPageTitle => 'নিষিদ্ধ ও নফল সময়';

  @override
  String get forbiddenTimesIntro =>
      'দিনে তিনটি সময় আছে যখন যেকোনো সালাত আদায় করা নিষিদ্ধ (মাকরূহ তাহরীমি)। রাসূলুল্লাহ ﷺ সূর্যোদয়, ঠিক দ্বিপ্রহরে এবং সূর্যাস্তের সময় সালাত আদায় করতে নিষেধ করেছেন — যে সময়ে কাফেররা সূর্যের পূজা করত। তবে এই সময়ে স্মরণে আসা ছুটে যাওয়া ফরজ সালাত কাযা করা যায়।';

  @override
  String get naflTimesIntro =>
      'ফরজ সালাত ছাড়াও কিছু নফল (ঐচ্ছিক) সালাত রয়েছে যেগুলোর নির্দিষ্ট উত্তম সময় আছে — এগুলো আল্লাহর নৈকট্য লাভ ও ফরজের ঘাটতি পূরণের মাধ্যম।';

  @override
  String get specialDetailForbiddenSunrise =>
      'সূর্যোদয় থেকে শুরু করে সূর্য দিগন্তের উপরে পুরোপুরি উঠে যাওয়া পর্যন্ত (প্রায় ১৫ মিনিট)। রাসূলুল্লাহ ﷺ বলেছেন সূর্য শয়তানের দুই শিংয়ের মাঝ দিয়ে উদিত হয়, তাই তা পুরোপুরি উঠার আগ পর্যন্ত সালাত স্থগিত থাকে।';

  @override
  String get specialDetailForbiddenZawal =>
      'যোহরের ওয়াক্ত শুরুর ঠিক আগে সূর্য যখন আকাশের সর্বোচ্চ বিন্দুতে (ইস্তিওয়া) অবস্থান করে সেই সংক্ষিপ্ত সময়। সূর্য ঢলে না পড়া পর্যন্ত কোনো সালাত আদায় হয় না।';

  @override
  String get specialDetailForbiddenSunset =>
      'সূর্য যখন হলদে হয়ে অস্ত যেতে শুরু করে তখন থেকে পুরোপুরি অস্ত (মাগরিব) যাওয়া পর্যন্ত। সূর্যোদয়ের মতোই অস্ত যাওয়ার সময় সালাত স্থগিত থাকে।';

  @override
  String get specialDetailIshraq =>
      'সূর্য পুরোপুরি উঠে যাওয়ার অল্প পরে আদায় করা দুই রাকাত। যে ব্যক্তি জামাতে ফজর পড়ে সূর্যোদয় পর্যন্ত যিকিরে বসে থাকে এবং পরে দুই রাকাত পড়ে, সে একটি পূর্ণ হজ ও উমরার সওয়াব পায়।';

  @override
  String get specialDetailDuha =>
      'চাশতের নামাজ — দুই থেকে বারো রাকাত, সূর্য ভালোভাবে উঠে যাওয়ার পর থেকে যাওয়ালের ঠিক আগ পর্যন্ত আদায় করা উত্তম। প্রতিদিন সকালে শরীরের প্রতিটি জোড়ার জন্য সদকা ওয়াজিব, আর এই রাকাতগুলো তার জন্য যথেষ্ট।';

  @override
  String get specialDetailSalatZawal =>
      'সূর্য মাথার উপর থেকে ঢলে পড়ার ঠিক পরে, যোহরের ফরজের আগমুহূর্তে আদায় করা হয়। রাসূলুল্লাহ ﷺ এই সময়ে নামাজ পড়তেন যখন আসমানের দরজাগুলো খুলে দেওয়া হয়।';

  @override
  String get specialDetailAwwabin =>
      'মাগরিব ও এশার মাঝে আদায় করা নফল রাকাত — আওয়াবিন (অধিক প্রত্যাবর্তনকারীদের) সালাত, দিনের কাজ শেষে আল্লাহর দিকে ফিরে আসার জন্য প্রিয়।';

  @override
  String get specialDetailTahajjud =>
      'রাতের শেষ তৃতীয়াংশে আদায় করা সালাত, সর্বোত্তম নফল সালাত। এ সময় আল্লাহ নিকটতম আসমানে নেমে আসেন এবং আহ্বানকারীর ডাকে সাড়া দেন।';

  @override
  String get setJamaat => 'জামাতের সময় সেট করুন';

  @override
  String get switchMosqueTitle => 'জামাতের মসজিদ';

  @override
  String get mosqueAutoBadge => 'অটো';

  @override
  String get mosqueOverrideBadge => 'ওভাররাইড';

  @override
  String get mosqueAutoSubtitle =>
      'আপনার সময়সূচি অনুযায়ী স্বয়ংক্রিয়ভাবে পরিবর্তন হচ্ছে';

  @override
  String get mosqueOverrideSubtitle =>
      'সাময়িক পরিবর্তন — সময়সূচিতে ফিরতে রিসেট করুন';

  @override
  String get mosqueResetToSchedule => 'সময়সূচিতে ফিরুন';

  @override
  String get mosqueManage => 'মসজিদ ও সময়সূচি ব্যবস্থাপনা';

  @override
  String get scheduleSectionTitle => 'অটো-সুইচ';

  @override
  String get scheduleModeManual => 'ম্যানুয়াল';

  @override
  String get scheduleModeAuto => 'অটো';

  @override
  String get scheduleAutoHint =>
      'দিন ও সময় অনুযায়ী প্রোডাক্টিভ মুসলিম মসজিদ বেছে নেবে।';

  @override
  String get scheduleRulesTitle => 'নিয়ম';

  @override
  String get scheduleRulesEmpty =>
      'এখনো কোনো নিয়ম নেই। স্বয়ংক্রিয় পরিবর্তনের জন্য একটি যোগ করুন।';

  @override
  String get scheduleAddRule => 'নিয়ম যোগ করুন';

  @override
  String get scheduleDefaultMosque => 'ডিফল্ট মসজিদ';

  @override
  String get scheduleDefaultHint => 'কোনো নিয়ম না মিললে এটি ব্যবহৃত হবে।';

  @override
  String get scheduleAllDay => 'সারাদিন';

  @override
  String get scheduleEveryDay => 'প্রতিদিন';

  @override
  String get scheduleFrom => 'শুরু';

  @override
  String get scheduleTo => 'শেষ';

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'সোম',
      '2': 'মঙ্গল',
      '3': 'বুধ',
      '4': 'বৃহ',
      '5': 'শুক্র',
      '6': 'শনি',
      '7': 'রবি',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get homeSetLocationTitle => 'আপনি কোথায় আছেন?';

  @override
  String get homeSetLocationBody =>
      'একবার অবস্থান বেছে নিন — প্রোডাক্টিভ মুসলিম সম্পূর্ণ অফলাইনে সঠিক নামাজের সময় হিসাব করবে।';

  @override
  String get homeSetLocationCta => 'অবস্থান সেট করুন';

  @override
  String hijriMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'মুহাররম',
      'm2': 'সফর',
      'm3': 'রবিউল আউয়াল',
      'm4': 'রবিউস সানি',
      'm5': 'জমাদিউল আউয়াল',
      'm6': 'জমাদিউস সানি',
      'm7': 'রজব',
      'm8': 'শাবান',
      'm9': 'রমজান',
      'm10': 'শাওয়াল',
      'm11': 'জিলকদ',
      'm12': 'জিলহজ',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String banglaMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'বৈশাখ',
      'm2': 'জ্যৈষ্ঠ',
      'm3': 'আষাঢ়',
      'm4': 'শ্রাবণ',
      'm5': 'ভাদ্র',
      'm6': 'আশ্বিন',
      'm7': 'কার্তিক',
      'm8': 'অগ্রহায়ণ',
      'm9': 'পৌষ',
      'm10': 'মাঘ',
      'm11': 'ফাল্গুন',
      'm12': 'চৈত্র',
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
    return '$prayer-এর সময় হয়েছে।';
  }

  @override
  String notifJamaatTitle(Object prayer) {
    return '$prayer জামাত শীঘ্রই';
  }

  @override
  String notifJamaatBody(Object time) {
    return 'জামাত $time এ।';
  }

  @override
  String get notifSahriTitle => 'সাহরি শেষ হতে চলেছে';

  @override
  String notifSahriBody(Object time) {
    return 'সাহরি শেষ $time এ — সময়মতো খাওয়া শেষ করুন।';
  }

  @override
  String get notifIftarTitle => 'ইফতারের সময় হয়েছে';

  @override
  String notifIftarBody(Object time) {
    return 'আল্লাহ আপনার রোজা কবুল করুন। ইফতার $time এ।';
  }

  @override
  String get notifMuhasabaTitle => 'সন্ধ্যার আত্মজিজ্ঞাসা';

  @override
  String get notifMuhasabaBody => 'আজকের মুহাসাবার জন্য এক মিনিট সময় হবে?';

  @override
  String get notifKeepAliveTitle => 'রিমাইন্ডার চালু রাখুন';

  @override
  String get notifKeepAliveBody =>
      'সুযোগ হলে একবার অ্যাপটি খুলুন, যাতে নামাজের রিমাইন্ডার চলতে থাকে।';

  @override
  String notifScheduledUntil(String when) {
    return 'রিমাইন্ডার নির্ধারিত আছে $when পর্যন্ত';
  }

  @override
  String get notifScheduledNone => 'এই মুহূর্তে কোনো রিমাইন্ডার নির্ধারিত নেই।';

  @override
  String get notifMarkPrayed => 'নামাজ পড়েছি';

  @override
  String get channelAzan => 'আজান';

  @override
  String get channelReminders => 'রিমাইন্ডার';

  @override
  String get channelSilent => 'নীরব নামাজ-সতর্কতা';

  @override
  String get channelBeep => 'নামাজ-সতর্কতা (বিপ)';

  @override
  String get notifSettingsTitle => 'নোটিফিকেশন';

  @override
  String get notifPermissionDeniedBanner =>
      'সিস্টেম সেটিংসে নোটিফিকেশন বন্ধ আছে। প্রোডাক্টিভ মুসলিম পুরোপুরি ব্যবহারযোগ্য থাকবে — আজান ও রিমাইন্ডার পেতে চালু করুন।';

  @override
  String get notifEnableCta => 'নোটিফিকেশন চালু করুন';

  @override
  String get notifExactAlarmBanner =>
      'ঠিক মিনিটে আজান পেতে সিস্টেম সেটিংসে প্রোডাক্টিভ মুসলিমের জন্য \"অ্যালার্ম ও রিমাইন্ডার\" অনুমতি দিন।';

  @override
  String get notifExactAlarmCta => 'এক্সাক্ট অ্যালার্ম অনুমতি দিন';

  @override
  String get notifBatteryHint =>
      'রিমাইন্ডার দেরিতে এলে সিস্টেম সেটিংসে প্রোডাক্টিভ মুসলিমকে ব্যাটারি অপটিমাইজেশন থেকে বাদ দিন।';

  @override
  String get notifPerPrayerHeader => 'নামাজের অ্যালার্ট';

  @override
  String get azanModeAzan => 'আজান';

  @override
  String get azanModeBeep => 'বিপ';

  @override
  String get azanModeSilent => 'নীরব';

  @override
  String get azanModeOff => 'বন্ধ';

  @override
  String get notifSahriToggle => 'সাহরি সতর্কতা';

  @override
  String get notifSahriToggleSub => 'সাহরি শেষ হওয়ার আগে';

  @override
  String get notifIftarToggle => 'ইফতার অ্যালার্ট';

  @override
  String get notifIftarToggleSub => 'মাগরিবের সময়, আনন্দের বার্তাসহ';

  @override
  String get notifJamaatToggle => 'জামাত রিমাইন্ডার';

  @override
  String get notifJamaatToggleSub => 'আমার মসজিদে জামাতের সময় লাগবে';

  @override
  String get notifMuhasabaToggle => 'সন্ধ্যার মুহাসাবা নাজ';

  @override
  String get notifMuhasabaToggleSub => 'এশার পরে একটি মৃদু রিমাইন্ডার';

  @override
  String get notifDailyToggle => 'দৈনিক রিমাইন্ডার';

  @override
  String get notifDailyToggleSub =>
      'আপনার বেছে নেওয়া সময়ে আজকের হাদিস বা দোয়া';

  @override
  String get notifDailyKindHadith => 'হাদিস';

  @override
  String get notifDailyKindDua => 'দোয়া';

  @override
  String get notifDailyTimeLabel => 'রিমাইন্ডারের সময়';

  @override
  String get notifDailyHadithTitle => 'আজকের হাদিস';

  @override
  String get notifDailyHadithBody => 'আজকের হাদিস প্রস্তুত — পড়তে ট্যাপ করুন।';

  @override
  String get notifDailyDuaTitle => 'আজকের দোয়া';

  @override
  String get notifDailyDuaBody => 'আজকের দোয়া প্রস্তুত — পড়তে ট্যাপ করুন।';

  @override
  String get leadTimeLabel => 'কত আগে';

  @override
  String get myMosqueTitle => 'আমার মসজিদ';

  @override
  String get myMosqueSubtitle => 'আপনার মসজিদের জামাতের সময়';

  @override
  String get addProfile => 'প্রোফাইল যোগ করুন';

  @override
  String get profileNameHint => 'মসজিদের নাম (যেমন: বাসা, অফিস)';

  @override
  String get defaultProfileName => 'আমার মসজিদ';

  @override
  String get deleteProfile => 'প্রোফাইল মুছুন';

  @override
  String deleteProfileConfirm(String name) {
    return '\"$name\" মুছবেন? এর জামাতের সময়গুলো মুছে যাবে।';
  }

  @override
  String get jamaatModeNone => 'নেই';

  @override
  String get jamaatModeOffset => 'অফসেট';

  @override
  String get jamaatModeFixed => 'নির্দিষ্ট';

  @override
  String offsetAfterStart(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'ওয়াক্ত শুরুর $countString মিনিট পরে';
  }

  @override
  String fixedAtTime(String time) {
    return 'জামাত $time এ';
  }

  @override
  String get pickTime => 'সময় বাছুন';

  @override
  String get jamaatReminderHint =>
      'জামাত রিমাইন্ডার নোটিফিকেশন সেটিংসে কনফিগার করা যায়।';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get delete => 'মুছুন';

  @override
  String get qiblaTitle => 'কিবলা';

  @override
  String get qiblaAligned => 'কিবলামুখী হয়েছেন';

  @override
  String qiblaHeading(String degrees, String cardinal) {
    return '$degrees° $cardinal';
  }

  @override
  String qiblaDistance(String km) {
    return 'কাবা শরীফ $km কিমি দূরে';
  }

  @override
  String get qiblaCalibrate => 'কম্পাস ক্যালিব্রেট করতে ফোনটি ৮-আকৃতিতে ঘোরান';

  @override
  String get qiblaSensorUnavailable => 'এই ডিভাইসে কম্পাস সেন্সর নেই';

  @override
  String qiblaVerbalBearing(String degrees, String cardinal) {
    return 'কিবলা উত্তর থেকে $degrees° $cardinal দিকে';
  }

  @override
  String get qiblaFinding => 'দিক খোঁজা হচ্ছে…';

  @override
  String get qiblaNeedsLocation => 'কিবলার দিক পেতে আগে অবস্থান সেট করুন';

  @override
  String get muhasabaTitle => 'মুহাসাবা';

  @override
  String get muhasabaFirstDayTitle => 'আপনার দৈনিক মুহাসাবা';

  @override
  String get muhasabaFirstDayBody =>
      'মুহাসাবা মানে কোমল আত্মজিজ্ঞাসা: ছোট ছোট দৈনিক আমল, সদয়ভাবে হিসাব রাখা। যা করেছেন টিক দিন — প্রতিটুকুই মূল্যবান।';

  @override
  String get muhasabaStart => 'বিসমিল্লাহ, শুরু করি';

  @override
  String trackerName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'salah_fajr': 'ফজরের নামাজ',
      'salah_dhuhr': 'যোহরের নামাজ',
      'salah_asr': 'আসরের নামাজ',
      'salah_maghrib': 'মাগরিবের নামাজ',
      'salah_isha': 'এশার নামাজ',
      'quran': 'কুরআন তিলাওয়াত',
      'azkar': 'আজকার',
      'sadaqah': 'সদকা',
      'tahajjud': 'তাহাজ্জুদ',
      'roza': 'রোজা',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String get addTracker => 'আইটেম যোগ করুন';

  @override
  String get editTracker => 'আইটেম সম্পাদনা';

  @override
  String get trackerNameHint => 'নাম (যেমন: সকালের আজকার)';

  @override
  String get trackerKindLabel => 'ধরন';

  @override
  String get kindYesNo => 'হ্যাঁ / না';

  @override
  String get kindCount => 'সংখ্যা';

  @override
  String get kindDuration => 'সময়কাল';

  @override
  String get targetLabel => 'দৈনিক লক্ষ্য (ঐচ্ছিক)';

  @override
  String get targetCountSuffix => 'বার';

  @override
  String get targetMinutesSuffix => 'মিনিট';

  @override
  String get archiveTracker => 'আর্কাইভ';

  @override
  String get unarchiveTracker => 'ফিরিয়ে আনুন';

  @override
  String get archiveExplain =>
      'আর্কাইভ করা আইটেম দৈনিক তালিকা থেকে সরে যায়, কিন্তু আগের সব এন্ট্রি সংরক্ষিত থাকে।';

  @override
  String get archivedSection => 'আর্কাইভ করা';

  @override
  String get dashboardTab => 'ড্যাশবোর্ড';

  @override
  String get todayTab => 'আজ';

  @override
  String get periodToday => 'আজ';

  @override
  String get periodWeek => 'সপ্তাহ';

  @override
  String get periodMonth => 'মাস';

  @override
  String get periodYear => 'বছর';

  @override
  String get overallCompletion => 'সার্বিক অগ্রগতি';

  @override
  String currentStreakLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString দিনের ধারা',
      one: '১ দিনের ধারা',
    );
    return '$_temp0';
  }

  @override
  String bestStreakLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'সেরা: $countString';
  }

  @override
  String get salahLockedToast => 'এই নামাজের সময় এখনো শুরু হয়নি';

  @override
  String a11yMarkPrayed(String prayer) {
    return '$prayer নামাজ পড়া হয়েছে হিসেবে চিহ্নিত করুন';
  }

  @override
  String a11yPrayerLocked(String prayer) {
    return '$prayer: এর সময় এখনো শুরু হয়নি';
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

    return '$totalStringটির মধ্যে $doneStringটি সম্পন্ন';
  }

  @override
  String vsPrevious(String trend) {
    String _temp0 = intl.Intl.selectLogic(trend, {
      'up': 'গত সময়ের চেয়ে ভালো',
      'same': 'গত সময়ের মতোই অবিচল',
      'down': 'নতুন করে শুরু — চালিয়ে যান',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String get emptyRange => 'এই সময়ে এখনো কোনো এন্ট্রি নেই';

  @override
  String minutesValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString মিনিট';
  }

  @override
  String get notYet => 'এখনো হয়নি';

  @override
  String get quranTitle => 'কুরআন';

  @override
  String get searchSurahHint => 'সূরা খুঁজুন…';

  @override
  String get continueReading => 'পড়া চালিয়ে যান';

  @override
  String surahMeta(int count, String place) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString আয়াত · $place';
  }

  @override
  String revelationName(String place) {
    String _temp0 = intl.Intl.selectLogic(place, {
      'meccan': 'মক্কী',
      'medinan': 'মাদানী',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String get readerFontSize => 'আরবি লেখার আকার';

  @override
  String get showTranslation => 'অনুবাদ দেখান';

  @override
  String get readerSettings => 'পড়ার সেটিংস';

  @override
  String get copyAyah => 'আয়াত কপি করুন';

  @override
  String get previousDay => 'আগের দিন';

  @override
  String get nextDay => 'পরের দিন';

  @override
  String get quranLoadError => 'কুরআনের লেখা খোলা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get copyLabel => 'কপি করুন';

  @override
  String get copiedLabel => 'কপি হয়েছে';

  @override
  String get ayahCopied => 'আয়াত কপি হয়েছে';

  @override
  String get bookmarksTitle => 'বুকমার্ক';

  @override
  String get bookmarksEmpty =>
      'এখনো কোনো বুকমার্ক নেই। যেকোনো আয়াতের বুকমার্ক আইকনে চাপ দিলে এখানে জমা হবে।';

  @override
  String get bookmarkLabel => 'বুকমার্ক';

  @override
  String get quranFirstOpen =>
      'বিসমিল্লাহ — পড়া শুরু করুন, কোথায় থেমেছিলেন প্রোডাক্টিভ মুসলিম মনে রাখবে।';

  @override
  String ayahShareSuffix(int surah, int ayah) {
    final intl.NumberFormat surahNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String surahString = surahNumberFormat.format(surah);
    final intl.NumberFormat ayahNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ayahString = ayahNumberFormat.format(ayah);

    return '— কুরআন $surahString:$ayahString';
  }

  @override
  String get duaTitle => 'দুআ ও তাসবিহ';

  @override
  String get tasbihTitle => 'তাসবিহ';

  @override
  String get asmaulHusnaTitle => 'আসমাউল হুসনা';

  @override
  String get asmaQuizTitle => 'নাম কুইজ';

  @override
  String get asmaLoadError => 'নামগুলো লোড করা যায়নি। পরে আবার চেষ্টা করুন।';

  @override
  String get asmaQuizModeNameToMeaning => 'নাম → অর্থ';

  @override
  String get asmaQuizModeMeaningToName => 'অর্থ → নাম';

  @override
  String get asmaQuizPromptMeaning => 'এই নামের অর্থ কী?';

  @override
  String get asmaQuizPromptName => 'কোন নামের এই অর্থ?';

  @override
  String asmaQuizProgress(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalString এর $currentString';
  }

  @override
  String get asmaQuizNext => 'পরবর্তী';

  @override
  String get asmaQuizSeeResult => 'ফলাফল দেখুন';

  @override
  String get asmaQuizResultTitle => 'কুইজ সম্পন্ন';

  @override
  String get asmaQuizResultEncouragement =>
      'যতবার এই নামগুলো ফিরে দেখবেন, ততই কাছে আসবেন। এখানে পাস-ফেল নেই — যখন ইচ্ছা ফিরে এসে আবার চেষ্টা করুন।';

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

    return 'সেরা স্কোর: $bestString';
  }

  @override
  String get asmaQuizPlayAgain => 'আবার চেষ্টা করুন';

  @override
  String get fastingTitle => 'সুন্নত রোজা';

  @override
  String get fastingSubtitle => 'প্রস্তাবিত দিন ও আপনার রেকর্ড';

  @override
  String get fastingTodayRecommended => 'আজ প্রস্তাবিত রোজা';

  @override
  String get fastingTodayNone => 'আজ কোনো নির্দিষ্ট সুন্নত রোজা নেই';

  @override
  String get fastingTodayNoneNote =>
      'আজ নির্দিষ্ট কোনো সুন্নত রোজা নেই, তবে নফল রোজার সওয়াব সবসময়ই রয়েছে।';

  @override
  String get fastingTodayForbidden => 'আজ রোজা রাখা নিষিদ্ধ';

  @override
  String get fastingTodayForbiddenNote =>
      'দুই ঈদের দিন এবং আইয়ামে তাশরীকে (১১–১৩ জিলহজ) রোজা রাখা নিষিদ্ধ।';

  @override
  String get fastingTodayRamadan => 'রমজান — ফরজ রোজা';

  @override
  String get fastingTodayRamadanNote =>
      'আজ রমজানের দিন, ফরজ রোজা। আল্লাহ কবুল করুন।';

  @override
  String get fastingLogToday => 'আজকের রোজা যোগ করুন';

  @override
  String get fastingLogVoluntary => 'নফল রোজা যোগ করুন';

  @override
  String get fastingLoggedToday => 'আজকের জন্য রেকর্ড হয়েছে';

  @override
  String get fastingLogTitle => 'আপনার রোজার রেকর্ড';

  @override
  String get fastingTotal => 'মোট';

  @override
  String get fastingThisMonth => 'এই মাসে';

  @override
  String get fastingThisHijriMonth => 'এই হিজরি মাসে';

  @override
  String get fastingFasted => 'রোজা রাখা হয়েছে';

  @override
  String fastingHeatmapLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই মাসে $countStringটি রোজা রেকর্ড হয়েছে',
      one: 'এই মাসে ১টি রোজা রেকর্ড হয়েছে',
      zero: 'এই মাসে কোনো রোজা রেকর্ড হয়নি',
    );
    return '$_temp0';
  }

  @override
  String get fastingUpcomingTitle => 'আসন্ন প্রস্তাবিত রোজা';

  @override
  String fastingKindName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'mondayThursday': 'সোম ও বৃহস্পতিবার',
      'whiteDays': 'আইয়ামে বীজ (শুভ্র দিন)',
      'ashura': 'আশুরা',
      'arafah': 'আরাফার দিন',
      'dhulHijjah': 'জিলহজের প্রথম দশ দিন',
      'shawwal': 'শাওয়ালের ছয় রোজা',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String fastingKindNote(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'mondayThursday':
          'সোম ও বৃহস্পতিবার আল্লাহর কাছে আমল পেশ করা হয়, আর নবীজি ﷺ তখন রোজা রাখা পছন্দ করতেন। (তিরমিজি)',
      'whiteDays':
          'প্রতি হিজরি মাসের ১৩, ১৪ ও ১৫ তারিখে রোজা রাখা সারা বছর রোজা রাখার সমান। (নাসায়ি)',
      'ashura':
          'আশুরার রোজা বিগত এক বছরের গুনাহের কাফফারা; সাথে ৯ তারিখেও রাখুন। (মুসলিম)',
      'arafah':
          'আরাফার দিনের রোজা বিগত ও আগামী বছরের গুনাহের কাফফারা। (মুসলিম)',
      'dhulHijjah':
          'এই দশ দিনের নেক আমলের চেয়ে প্রিয় কোনো আমল আল্লাহর কাছে নেই। (বুখারি)',
      'shawwal':
          'রমজানের পর শাওয়ালের ছয় রোজা সারা বছর রোজা রাখার সমান। (মুসলিম)',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get achievementsTitle => 'অর্জন';

  @override
  String get achievementsSubtitle =>
      'প্রতিটি ছোট পদক্ষেপই মূল্যবান — চালিয়ে যান।';

  @override
  String achievementHow(String kind, String count) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'streak': 'মুহাসাবায় পরপর $count দিন অন্তত একটি আমল লিখুন।',
      'salah': '$countটি ভিন্ন দিনে সালাত চিহ্নিত করুন।',
      'dhikr': 'তাসবিহ দিয়ে $countটি যিকর গুনে সংরক্ষণ করুন।',
      'quranStart': 'কুরআন খুলে পড়া শুরু করুন।',
      'quran': '$count দিন কুরআন পড়া সম্পন্ন করুন।',
      'bookmark': '$countটি আয়াত বুকমার্ক করুন।',
      'fast': '$countটি রোজা লিখুন।',
      'other': 'চালিয়ে যান।',
    });
    return '$_temp0';
  }

  @override
  String get achievementUnlocked => 'অর্জিত';

  @override
  String achievementsCount(int unlocked, int total) {
    final intl.NumberFormat unlockedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String unlockedString = unlockedNumberFormat.format(unlocked);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalStringটির মধ্যে $unlockedStringটি অর্জিত';
  }

  @override
  String achievementCategory(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'streaks': 'ধারাবাহিকতা',
      'salah': 'সালাত',
      'dhikr': 'যিকর',
      'quran': 'কুরআন',
      'fasting': 'রোজা',
      'other': 'অর্জন',
    });
    return '$_temp0';
  }

  @override
  String achievementName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'streak_3': 'পরপর তিন দিন',
      'streak_7': 'এক সপ্তাহের ধারা',
      'streak_30': 'এক মাসের ইবাদত',
      'streak_100': 'একশো দিন',
      'salah_10': 'দশ দিন সালাত',
      'salah_50': 'পঞ্চাশ দিন সালাত',
      'salah_200': 'দুইশো দিন সালাত',
      'dhikr_100': 'প্রথম একশো যিকর',
      'dhikr_1000': 'এক হাজার যিকর',
      'dhikr_10000': 'দশ হাজার যিকর',
      'quran_start': 'কুরআন খোলা হলো',
      'quran_days_7': 'কুরআনের সাথে এক সপ্তাহ',
      'quran_days_30': 'কুরআনের সাথে এক মাস',
      'quran_bookmark_5': 'পাঁচটি বুকমার্ক',
      'fast_1': 'প্রথম রোজা',
      'fast_10': 'দশটি রোজা',
      'fast_30': 'ত্রিশটি রোজা',
      'other': 'অর্জন',
    });
    return '$_temp0';
  }

  @override
  String duaCategoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'morning_evening': 'সকাল-সন্ধ্যা',
      'sleep': 'ঘুম',
      'waking': 'ঘুম থেকে ওঠা',
      'food': 'খাবার-পানীয়',
      'home': 'ঘরে প্রবেশ-প্রস্থান',
      'travel': 'সফর',
      'salah': 'নামাজ',
      'distress': 'দুশ্চিন্তা ও মুক্তি',
      'wudu': 'অজু',
      'clothes': 'পোশাক পরিধান',
      'weather': 'বৃষ্টি ও আবহাওয়া',
      'istighfar': 'ইস্তিগফার',
      'gratitude': 'কৃতজ্ঞতা',
      'protection': 'হেফাজত',
      'sneezing': 'হাঁচি',
      'marketplace': 'বাজার',
      'adhan': 'আযান ও ইকামত',
      'toilet': 'টয়লেট',
      'knowledge': 'জ্ঞান ও হিদায়াত',
      'family': 'পরিবার ও বিবাহ',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String duaCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি দুআ';
  }

  @override
  String repeatTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString বার পড়ুন';
  }

  @override
  String get referenceLabel => 'সূত্র';

  @override
  String get ruqyahTitle => 'রুকইয়া';

  @override
  String get ruqyahSubtitle => 'কুরআনি সুরক্ষা ও আরোগ্য';

  @override
  String get ruqyahHowToTitle => 'রুকইয়া কীভাবে করবেন';

  @override
  String get ruqyahHowToBody =>
      'এই আয়াত ও দোয়াগুলো আন্তরিকতার সাথে পড়ুন — দৃঢ় বিশ্বাস রাখুন যে আরোগ্য কেবল আল্লাহর পক্ষ থেকে। নিজের উপর বা যাকে রুকইয়া করা হচ্ছে তার উপর, কিংবা পান করার পানির উপর হালকা ফুঁ দিন। রুকইয়া কেবল কুরআন ও সহিহ সুন্নাহ থেকে — কখনো তাবিজ বা ঝাড়ফুঁককারীর কাছে যাবেন না।';

  @override
  String ruqyahCategoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'protection': 'সুরক্ষা',
      'three_quls': 'তিন কুল',
      'healing': 'আরোগ্য ও অসুস্থতা',
      'evil_eye': 'বদনজর ও হিংসা',
      'sihr_jinn': 'জাদু, জিন ও ওয়াসওয়াসা',
      'anxiety_grief': 'দুশ্চিন্তা, দুঃখ ও বিপদ',
      'sleep': 'ঘুম ও দুঃস্বপ্ন',
      'morning_evening': 'সকাল-সন্ধ্যা',
      'enemies': 'শত্রু ও জুলুম',
      'children': 'সন্তানের সুরক্ষা',
      'fitan': 'ফিতনা ও দাজ্জাল',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String ruqyahCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি আমল';
  }

  @override
  String get tasbihTarget => 'লক্ষ্য';

  @override
  String get tasbihCustom => 'কাস্টম';

  @override
  String get tasbihReset => 'রিসেট';

  @override
  String get tasbihDiscard => 'বাদ দিন';

  @override
  String get tasbihUndo => 'শেষ গণনা ফেরত নিন';

  @override
  String get tasbihResetConfirm => 'এই রাউন্ড ইতিহাসে রেখে রিসেট করবেন?';

  @override
  String tasbihSessionLine(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'আজ: $countString গণনা';
  }

  @override
  String get tasbihTargetReached => 'লক্ষ্য পূর্ণ — আল্লাহ কবুল করুন';

  @override
  String get ramadanTitle => 'রমজান';

  @override
  String rozaDayOf(int day, int total) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalString দিনের $dayStringতম রোজা';
  }

  @override
  String daysUntilRamadan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'রমজানের আর $countString দিন',
      one: 'রমজানের আর ১ দিন',
    );
    return '$_temp0';
  }

  @override
  String get monthTable => 'এ মাসের সাহরি ও ইফতার';

  @override
  String get zakatTitle => 'যাকাত ক্যালকুলেটর';

  @override
  String get zakatSubtitle => 'আপনার সম্পদের ওপর প্রদেয় যাকাত হিসাব করুন';

  @override
  String get zakatCash => 'নগদ টাকা';

  @override
  String get zakatBank => 'ব্যাংক ব্যালেন্স';

  @override
  String get zakatGold => 'স্বর্ণ (গ্রাম)';

  @override
  String get zakatSilver => 'রুপা (গ্রাম)';

  @override
  String get zakatBusiness => 'ব্যবসায়িক সম্পদ';

  @override
  String get zakatInvestments => 'বিনিয়োগ';

  @override
  String get zakatOwed => 'পাওনা টাকা';

  @override
  String get zakatDebts => 'ঋণ (বাদ যাবে)';

  @override
  String get zakatGoldPrice => 'প্রতি গ্রাম স্বর্ণের দাম';

  @override
  String get zakatSilverPrice => 'প্রতি গ্রাম রুপার দাম';

  @override
  String get zakatNeedPrice =>
      'নিসাব হিসাব করতে আজকের স্বর্ণ বা রুপার দাম লিখুন।';

  @override
  String get zakatInvalidNumber => 'সঠিক সংখ্যা লিখুন';

  @override
  String get zakatNeedMetalPrice => 'যে ধাতুর গ্রাম লিখেছেন, তার দামও লিখুন।';

  @override
  String get zakatCalculate => 'হিসাব করুন';

  @override
  String zakatNisab(String amount) {
    return 'নিসাব সীমা: $amount';
  }

  @override
  String zakatDue(String amount) {
    return 'প্রদেয় যাকাত: $amount';
  }

  @override
  String get zakatNotPayable =>
      'আপনার যাকাতযোগ্য সম্পদ নিসাবের নিচে — যাকাত ফরজ হয়নি।';

  @override
  String get fitraInfo =>
      'সদাকাতুল ফিতর ঈদের নামাজের আগে জনপ্রতি আদায় করতে হয় — প্রায় এক সা\' (~২.৫–৩ কেজি) প্রধান খাদ্য বা তার মূল্য, পরিবারের প্রত্যেকের জন্য।';

  @override
  String get calendarTitle => 'ক্যালেন্ডার';

  @override
  String islamicDayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'hijriNewYear': 'হিজরি নববর্ষ',
      'ashura': 'আশুরা',
      'mawlid': 'ঈদে মিলাদুন্নবী',
      'israMiraj': 'ইসরা ও মিরাজ',
      'nisfShaban': 'শবে বরাত',
      'ramadanStart': 'রমজান শুরু',
      'laylatulQadr': 'লাইলাতুল কদর',
      'eidAlFitr': 'ঈদুল ফিতর',
      'arafah': 'আরাফার দিন',
      'eidAlAdha': 'ঈদুল আজহা',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String get onboardingWelcomeTitle => 'হৃদয়ের দৈনিক দ্বীনের সঙ্গী';

  @override
  String get onboardingWelcomeBody =>
      'নামাজের সময়, কিবলা, কুরআন, দুআ আর কোমল আত্মজিজ্ঞাসা — সব অফলাইনে, সব আপনার।';

  @override
  String get onboardingLanguageTitle => 'ভাষা বেছে নিন';

  @override
  String get onboardingLocationTitle => 'আপনি কোথায় আছেন?';

  @override
  String get onboardingMadhabTitle => 'আসরের হিসাব';

  @override
  String get onboardingMadhabNote =>
      'এটি শুধু আসরের সময়ে প্রভাব ফেলে — সেটিংসে যেকোনো সময় বদলাতে পারবেন।';

  @override
  String get onboardingMethodTitle => 'হিসাবের পদ্ধতি';

  @override
  String get onboardingMethodNote =>
      'আপনার অঞ্চলের জন্য প্রস্তাবিত। পরে সেটিংসে বদলানো যাবে।';

  @override
  String get onboardingNotifTitle => 'কোমল স্মরণে থাকুন';

  @override
  String get onboardingNotifBody =>
      'প্রতি ওয়াক্তে আজান, সাহরি-ইফতার অ্যালার্ট, আর সন্ধ্যার মুহাসাবা নাজ — সব আপনার ডিভাইসেই হিসাব হয়।';

  @override
  String get onboardingNotifDenied =>
      'নোটিফিকেশন বন্ধ আছে। যেকোনো সময় সেটিংস → নোটিফিকেশন থেকে চালু করতে পারবেন।';

  @override
  String get onboardingNotifAllow => 'নোটিফিকেশন চালু করুন';

  @override
  String get onboardingNotifSkip => 'পরে দেখব';

  @override
  String get onboardingFinishTitle => 'বিসমিল্লাহ';

  @override
  String get onboardingFinishBody =>
      'সব প্রস্তুত। আপনার দিনগুলো নূরে ভরে উঠুক।';

  @override
  String get onboardingBegin => 'শুরু করুন';

  @override
  String get next => 'পরবর্তী';

  @override
  String get back => 'পেছনে';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get appLockEnterPin => 'আপনার পিন দিন';

  @override
  String get appLockSetPin => '৪ সংখ্যার পিন সেট করুন';

  @override
  String get appLockConfirmPin => 'পিনটি আবার দিন';

  @override
  String get appLockPinMismatch => 'পিন মেলেনি — আবার চেষ্টা করুন';

  @override
  String get appLockBiometricOfferTitle => 'আঙুলের ছাপ বা মুখ দিয়ে খুলবেন?';

  @override
  String get appLockBiometricOfferBody => 'পিন সবসময় বিকল্প হিসেবে কাজ করবে।';

  @override
  String get appLockBiometricUse => 'চালু করুন';

  @override
  String get appLockBiometricSkip => 'এখন না';

  @override
  String get appLockWrongPin => 'ভুল পিন — আবার চেষ্টা করুন';

  @override
  String get appLockUseBiometric => 'ফিঙ্গারপ্রিন্ট / ফেস ব্যবহার করুন';

  @override
  String get appLockEnable => 'অ্যাপ লক';

  @override
  String get appLockEnableSub =>
      'প্রোডাক্টিভ মুসলিম খুলতে পিন (ও বায়োমেট্রিক) লাগবে';

  @override
  String get appLockDisable => 'অ্যাপ লক বন্ধ করুন';

  @override
  String get appLockDelete => 'শেষ সংখ্যা মুছুন';

  @override
  String appLockThrottled(String time) {
    return 'অনেকবার ভুল হয়েছে। $time পরে আবার চেষ্টা করুন।';
  }

  @override
  String get appLockForgotPin => 'পিন ভুলে গেছেন?';

  @override
  String get appLockForgotReason =>
      'অ্যাপের পিন রিসেট করতে নিশ্চিত করুন যে এটি আপনি';

  @override
  String get appLockNoDeviceLockTitle => 'এখানে পিন রিসেট করা যাচ্ছে না';

  @override
  String get appLockNoDeviceLockBody =>
      'আপনার ডিভাইসে কোনো স্ক্রিন লক নেই, তাই আপনাকে যাচাই করা যাচ্ছে না। ডিভাইসের সেটিংসে স্ক্রিন লক চালু করে আবার চেষ্টা করুন। অ্যাপের ডেটা মুছে ফেললেও পিন সরে যায়, তবে আপনার সংরক্ষিত অগ্রগতিও মুছে যাবে।';

  @override
  String get appLockNewPin => 'নতুন ৪-সংখ্যার পিন দিন';

  @override
  String appLockPinProgress(int entered) {
    final intl.NumberFormat enteredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String enteredString = enteredNumberFormat.format(entered);

    return '৪টির মধ্যে $enteredStringটি সংখ্যা দেওয়া হয়েছে';
  }

  @override
  String a11yIncrease(String label) {
    return '$label বাড়ান';
  }

  @override
  String a11yDecrease(String label) {
    return '$label কমান';
  }

  @override
  String get prayerSheetWindow => 'ওয়াক্তের সময়';

  @override
  String get prayerSheetRakaat => 'রাকাত';

  @override
  String get rakaatFard => 'ফরজ';

  @override
  String get rakaatSunnah => 'সুন্নত';

  @override
  String get rakaatWitr => 'বিতর';

  @override
  String get prayerSheetNoJamaat => 'জামাত সেট করা নেই';

  @override
  String get prayerFazilatFajr =>
      'ফজরের দুই রাকাত সুন্নত দুনিয়া ও তার সবকিছুর চেয়ে উত্তম। দিন ও রাতের ফেরেশতারা এ নামাজের সাক্ষী হন।';

  @override
  String get prayerFazilatDhuhr =>
      'দুপুরে আসমানের দরজাগুলো খুলে দেওয়া হয়; নবীজি তখন চার রাকাত পড়তে ভালোবাসতেন।';

  @override
  String get prayerFazilatAsr =>
      'মধ্যবর্তী নামাজের হেফাজত করো। যে আসর পড়ে, সে সূর্যোদয় ও সূর্যাস্তের আগে জাহান্নামে প্রবেশ করবে না।';

  @override
  String get prayerFazilatMaghrib =>
      'সূর্য ডোবার সাথে সাথেই পড়ে নাও। ফরজের পর দুই রাকাত হালকা সুন্নত রয়েছে।';

  @override
  String get prayerFazilatIsha =>
      'জামাতে ইশা পড়া অর্ধেক রাত দাঁড়ানোর সমান; ফজরসহ পড়লে সারা রাত দাঁড়ানোর সমান।';

  @override
  String get dailyKindAyah => 'আয়াত';

  @override
  String get dailyAyahTitle => 'আজকের আয়াত';

  @override
  String get duaOfDayTitle => 'আজকের দোয়া';

  @override
  String dailyAyahReference(String surah, String ayah) {
    return '$surah, আয়াত $ayah';
  }

  @override
  String get tasbihQuickTitle => 'তাসবিহ';

  @override
  String get tasbihQuickHint => 'গুনতে ট্যাপ করুন';

  @override
  String get qiblaChipLabel => 'কিবলা';

  @override
  String get qiblaChipNeedsLocation => 'অবস্থান দিন';

  @override
  String get dayTimelineTitle => 'আজকের সময়রেখা';

  @override
  String streakMilestone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString দিনের ধারা! 🎉';
  }

  @override
  String get calculatorsTitle => 'ক্যালকুলেটর';

  @override
  String get calculatorsSubtitle => 'যাকাত, ফিতরা, কাযা, উত্তরাধিকার ও বয়স';

  @override
  String get fitraTitle => 'ফিতরা ক্যালকুলেটর';

  @override
  String get fitraSubtitle => 'আপনার পরিবারের জন্য সাদাকাতুল ফিতর হিসাব করুন';

  @override
  String get fitraStaple => 'প্রধান খাদ্য';

  @override
  String get fitraStapleWheat => 'গম / আটা';

  @override
  String get fitraStapleBarley => 'যব';

  @override
  String get fitraStapleDates => 'খেজুর';

  @override
  String get fitraStapleRaisins => 'কিশমিশ';

  @override
  String get fitraPricePerKg => 'প্রতি কেজির দাম';

  @override
  String get fitraPeople => 'ব্যক্তির সংখ্যা';

  @override
  String get fitraCalculate => 'হিসাব করুন';

  @override
  String fitraPerPerson(String amount) {
    return 'জনপ্রতি: $amount';
  }

  @override
  String fitraTotal(String amount) {
    return 'মোট ফিতরা: $amount';
  }

  @override
  String fitraWeightNote(String kg) {
    return 'জনপ্রতি $kg কেজি অনুযায়ী';
  }

  @override
  String get fitraBeforeEid => 'ঈদের নামাজের আগে আদায় করুন।';

  @override
  String get qazaTitle => 'কাযা নামাজ ক্যালকুলেটর';

  @override
  String get qazaSubtitle =>
      'আদায় করার জন্য ছুটে যাওয়া ফরজ নামাজের আনুমানিক হিসাব';

  @override
  String get qazaStartDate => 'শুরুর তারিখ';

  @override
  String get qazaEndDate => 'শেষের তারিখ';

  @override
  String get qazaSelectDate => 'তারিখ নির্বাচন করুন';

  @override
  String get qazaIncludeWitr => 'বিতর অন্তর্ভুক্ত করুন (হানাফি)';

  @override
  String get qazaAlreadyMadeUp => 'ইতিমধ্যে আদায়কৃত (প্রতি নামাজ)';

  @override
  String get qazaEndBeforeStart => 'শেষের তারিখ শুরুর তারিখের আগে পড়েছে।';

  @override
  String get qazaCalculate => 'হিসাব করুন';

  @override
  String qazaDays(String count) {
    return 'সময়কাল: $count দিন';
  }

  @override
  String qazaPerPrayer(String count) {
    return 'প্রতি নামাজ: $count';
  }

  @override
  String qazaWitr(String count) {
    return 'বিতর: $count';
  }

  @override
  String qazaTotal(String count) {
    return 'মোট ছুটে যাওয়া: $count';
  }

  @override
  String get qazaNote =>
      'পরিকল্পনায় সহায়তার জন্য একটি আনুমানিক হিসাব — অপরাধবোধ ছাড়াই ধীরে ধীরে আদায় করুন।';

  @override
  String get ageTitle => 'বয়স ক্যালকুলেটর';

  @override
  String get ageSubtitle => 'গ্রেগরিয়ান ও হিজরি উভয় ক্যালেন্ডারে আপনার বয়স';

  @override
  String get ageBirthDate => 'জন্ম তারিখ';

  @override
  String get ageAsOf => 'যে তারিখ অনুযায়ী';

  @override
  String get ageSelectDate => 'তারিখ নির্বাচন করুন';

  @override
  String get ageCalculate => 'হিসাব করুন';

  @override
  String get ageGregorian => 'গ্রেগরিয়ান বয়স';

  @override
  String get ageHijri => 'হিজরি বয়স';

  @override
  String ageValue(String years, String months, String days) {
    return '$years বছর, $months মাস, $days দিন';
  }

  @override
  String ageTotalDays(String count) {
    return 'মোট: $count দিন';
  }

  @override
  String get faraidTitle => 'উত্তরাধিকার ক্যালকুলেটর';

  @override
  String get faraidSubtitle =>
      'সাধারণ উত্তরাধিকারীদের অংশ অনুমান করুন (ফারায়েজ)';

  @override
  String get faraidEstate => 'সম্পত্তির পরিমাণ';

  @override
  String get faraidSpouse => 'স্বামী/স্ত্রী';

  @override
  String get faraidNone => 'কেউ নয়';

  @override
  String get faraidHusband => 'স্বামী';

  @override
  String get faraidWife => 'স্ত্রী';

  @override
  String get faraidWives => 'স্ত্রীর সংখ্যা';

  @override
  String get faraidFather => 'পিতা';

  @override
  String get faraidMother => 'মাতা';

  @override
  String get faraidSons => 'ছেলে';

  @override
  String get faraidDaughters => 'মেয়ে';

  @override
  String get faraidBrothers => 'সহোদর ভাই';

  @override
  String get faraidSisters => 'সহোদর বোন';

  @override
  String get faraidCalculate => 'হিসাব করুন';

  @override
  String faraidShare(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get faraidAwlNote =>
      'অংশসমূহ সম্পত্তির চেয়ে বেশি — আনুপাতিকভাবে কমানো হয়েছে (\'আউল)।';

  @override
  String get faraidRaddNote =>
      'উদ্বৃত্ত উত্তরাধিকারীদের ফিরিয়ে দেওয়া হয়েছে (রদ্দ)।';

  @override
  String faraidUnallocated(String amount) {
    return 'অবণ্টিত (অন্যান্য আত্মীয়দের জন্য): $amount';
  }

  @override
  String get faraidDisclaimer =>
      'এটি কেবল সাধারণ উত্তরাধিকারীদের জন্য একটি অনুমান। চূড়ান্ত সিদ্ধান্তের জন্য একজন যোগ্য আলেমের পরামর্শ নিন।';

  @override
  String get faraidHeirHusband => 'স্বামী';

  @override
  String get faraidHeirWife => 'স্ত্রী';

  @override
  String get faraidHeirFather => 'পিতা';

  @override
  String get faraidHeirMother => 'মাতা';

  @override
  String get faraidHeirSon => 'ছেলে';

  @override
  String get faraidHeirDaughter => 'মেয়ে';

  @override
  String get faraidHeirBrother => 'ভাই';

  @override
  String get faraidHeirSister => 'বোন';

  @override
  String get hadithOfDayTitle => 'আজকের হাদিস';

  @override
  String get hadithTitle => 'হাদিস';

  @override
  String get hadithNotFound => 'এই হাদিসটি পাওয়া যায়নি।';

  @override
  String get hadithSubtitle => 'চিন্তা-ভাবনার জন্য সহিহ বর্ণনা';

  @override
  String hadithNarratedBy(String narrator) {
    return 'বর্ণনায় $narrator';
  }

  @override
  String hadithTopicName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'intention': 'নিয়ত ও ইখলাস',
      'faith': 'ঈমান',
      'character': 'চরিত্র ও আখলাক',
      'speech': 'কথা ও জিহ্বা',
      'knowledge': 'ইলম অর্জন',
      'charity': 'দান ও কল্যাণ',
      'mercy': 'দয়া ও বিনয়',
      'worship': 'ইবাদত',
      'dunya': 'দুনিয়া ও আখিরাত',
      'other': 'অন্যান্য',
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
      other: '$countStringটি হাদিস',
      one: '১টি হাদিস',
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
      other: '$countStringটি অধ্যায়',
      one: '১টি অধ্যায়',
    );
    return '$_temp0';
  }

  @override
  String get hadithBooksCardTitle => 'পূর্ণ সংকলন';

  @override
  String get hadithBooksTitle => 'হাদিস সংকলন';

  @override
  String get hadithBooksSubtitle => 'ওপেন ডেটাসেট থেকে পূর্ণ কিতাব ব্রাউজ করুন';

  @override
  String get hadithBookAllSahih => 'প্রতিটি হাদিস সহিহ';

  @override
  String hadithGradeLabel(String grade) {
    return 'মান: $grade';
  }

  @override
  String get hadithLoadError =>
      'লোড করা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।';

  @override
  String get hadithRetry => 'আবার চেষ্টা করুন';

  @override
  String get hadithSourceNote =>
      'সূত্র: fawazahmed0/hadith-api (পাবলিক ডোমেইন)';

  @override
  String get hadithSourceNoteBn => 'বাংলা সূত্র: hadithbangla (ওপেন সোর্স)';

  @override
  String get hadithEnglishOnly => 'শুধু ইংরেজি';

  @override
  String get hadithBengaliUnavailable =>
      'বাংলা অনুবাদ নেই — ইংরেজি দেখানো হচ্ছে';

  @override
  String get hadithBengaliUnavailableSection =>
      'এই কিতাবের বাংলা অনুবাদ এখনো নেই — ইংরেজি দেখানো হচ্ছে।';

  @override
  String get duaSearchHint => 'দোয়া খুঁজুন';

  @override
  String get duaSearchTitle => 'খুঁজুন';

  @override
  String get duaNoResults => 'কোনো দোয়া পাওয়া যায়নি';

  @override
  String get duaFavoritesTitle => 'প্রিয়';

  @override
  String get duaFavoritesEmpty =>
      'যেকোনো দোয়ার হার্ট আইকনে চাপ দিয়ে এখানে সংরক্ষণ করুন';

  @override
  String get favoriteAddLabel => 'প্রিয়তে যোগ করুন';

  @override
  String get favoriteRemoveLabel => 'প্রিয় থেকে সরান';

  @override
  String get widgetNextPrayerLabel => 'পরবর্তী নামাজ';

  @override
  String get nearbyMosquesLabel => 'মসজিদ';

  @override
  String get nearbyMosquesLaunchError =>
      'ম্যাপ খোলা গেল না। একটি ম্যাপ অ্যাপ ইনস্টল আছে কিনা দেখুন।';

  @override
  String get nearbyMosquesLocationError =>
      'কাছের মসজিদ খুঁজতে আগে আপনার অবস্থান সেট করুন।';

  @override
  String get expenseTitle => 'খরচের হিসাব';

  @override
  String get expenseSubtitle => 'মাসিক হিসাব, অপচয় নয়';

  @override
  String get expenseAdd => 'খরচ যোগ করুন';

  @override
  String get expenseSave => 'সংরক্ষণ';

  @override
  String get expenseAmountHint => 'পরিমাণ';

  @override
  String get expenseNoteHint => 'নোট (ঐচ্ছিক)';

  @override
  String get expenseMonthTotal => 'মোট খরচ';

  @override
  String get expensePrevMonth => 'আগের মাস';

  @override
  String get expenseNextMonth => 'পরের মাস';

  @override
  String get expenseEmpty => 'কোনো খরচ লেখা হয়নি।';

  @override
  String get expenseIsrafReminder =>
      '“আর যারা ব্যয় করে, তারা অপচয় করে না, কৃপণতাও করে না; বরং তারা এর মাঝে মধ্যপন্থা অবলম্বন করে।” (আল-ফুরকান ২৫:৬৭)';

  @override
  String expenseCategory(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'need': 'প্রয়োজন',
      'family': 'পরিবার',
      'sadaqah': 'সাদাকাহ',
      'want': 'শখ',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get expenseEdit => 'খরচ সম্পাদনা';

  @override
  String get expenseDeleted => 'খরচ মুছে ফেলা হয়েছে';

  @override
  String get expenseUndo => 'ফিরিয়ে আনুন';

  @override
  String get expenseSaveFailed => 'সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get expenseAmountInvalid => 'পূর্ণ সংখ্যায় পরিমাণ লিখুন';

  @override
  String get expenseBudget => 'মাসিক বাজেট';

  @override
  String get expenseBudgetClear => 'বাজেট মুছুন';

  @override
  String expenseBudgetLeft(String left, String budget) {
    return '$budget এর মধ্যে $left বাকি';
  }

  @override
  String expenseBudgetOver(String amount) {
    return 'বাজেটের চেয়ে $amount বেশি — শখের খরচ ভেবে দেখুন';
  }

  @override
  String expenseVsLastMonth(String dir, String amount) {
    String _temp0 = intl.Intl.selectLogic(dir, {
      'more': 'গত মাসের চেয়ে $amount বেশি',
      'less': 'গত মাসের চেয়ে $amount কম',
      'other': 'গত মাসের সমান',
    });
    return '$_temp0';
  }

  @override
  String expenseVsLastMonthSoFar(String dir, String amount) {
    String _temp0 = intl.Intl.selectLogic(dir, {
      'more': 'গত মাসের এই সময়ের চেয়ে $amount বেশি',
      'less': 'গত মাসের এই সময়ের চেয়ে $amount কম',
      'other': 'গত মাসের এই সময়ের সমান',
    });
    return '$_temp0';
  }

  @override
  String get expenseYesterday => 'গতকাল';

  @override
  String get expenseCategoryBudgetHint =>
      'ক্যাটাগরিতে চাপলে শুধু সেই খরচ দেখাবে; বাজেট দিতে চেপে ধরুন (সাদাকাহ: লক্ষ্য)';

  @override
  String expenseCategoryBudgetTitle(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'need': 'প্রয়োজনের বাজেট',
      'family': 'পরিবারের বাজেট',
      'sadaqah': 'মাসিক সাদাকাহর লক্ষ্য',
      'want': 'শখের বাজেট',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get expenseBackup => 'ব্যাকআপ';

  @override
  String get expenseExportCsv => 'CSV ব্যাকআপ কপি করুন';

  @override
  String get expenseImportCsv => 'কপি করা CSV থেকে ফেরত আনুন';

  @override
  String get expenseExported =>
      'কপি হয়েছে। নিরাপদে রাখতে নোট, ইমেইল বা স্প্রেডশিটে পেস্ট করুন।';

  @override
  String get expenseImportInvalid => 'ক্লিপবোর্ডে খরচের ব্যাকআপ নেই।';

  @override
  String expenseImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি খরচ ফেরত আনা হয়েছে',
      zero: 'ফেরত আনার মতো নতুন কিছু নেই',
    );
    return '$_temp0';
  }

  @override
  String get hadithSearchHint => 'হাদিস খুঁজুন';

  @override
  String get hadithNoResults => 'কোনো হাদিস পাওয়া যায়নি';

  @override
  String get ruqyahSearchHint => 'রুকইয়াহ খুঁজুন';

  @override
  String get ruqyahNoResults => 'কিছু পাওয়া যায়নি';

  @override
  String get scheduleRuleRemoved => 'সময়সূচির নিয়ম মুছে ফেলা হয়েছে';

  @override
  String get countdownSeeDay => 'পুরো দিন';

  @override
  String get settingHomeCards => 'হোম কার্ড';

  @override
  String get settingHomeCardsSub => 'হোমে কোন অংশগুলো দেখাবে বেছে নিন';

  @override
  String get homeCardQuickActions => 'দ্রুত শর্টকাট';

  @override
  String get homeCardDaily => 'আজকের আয়াত, হাদিস ও দোয়া';
}
