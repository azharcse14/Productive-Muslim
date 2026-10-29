import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_params.dart';

/// The two Asr choices offered in pickers; "Standard" stores [Madhab.shafi]
/// (maliki/hanbali stay valid stored values with the same Asr).
const asrMadhabChoices = [Madhab.hanafi, Madhab.shafi];

/// [m] as one of [asrMadhabChoices].
Madhab asrMadhabOf(Madhab m) => m == Madhab.hanafi ? m : Madhab.shafi;

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
