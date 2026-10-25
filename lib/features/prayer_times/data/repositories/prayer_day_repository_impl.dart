import 'package:adhan_dart/adhan_dart.dart' as adhan;

import '../../../../core/utils/result.dart';
import '../../../settings/domain/entities/location_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../domain/entities/prayer_day.dart';
import '../../domain/repositories/prayer_day_repository.dart';

/// adhan_dart-backed prayer computation. adhan_dart returns UTC instants;
/// every value is converted to the location's wall clock through
/// [ZonedClock] before leaving this class (guide §5).
final class PrayerDayRepositoryImpl implements PrayerDayRepository {
  const PrayerDayRepositoryImpl(this._clock);

  final ZonedClock _clock;

  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) {
    try {
      final coordinates =
          adhan.Coordinates(location.latitude, location.longitude);
      final calcParams = _calculationParameters(params);
      final times = adhan.PrayerTimes(
        date: DateTime.utc(date.year, date.month, date.day, 12),
        coordinates: coordinates,
        calculationParameters: calcParams,
        precision: true,
      );

      DateTime wall(DateTime utc) => _clock.instantAt(location, utc);

      return Result.success(
        PrayerDay(
          fajr: wall(times.fajr),
          sunrise: wall(times.sunrise),
          dhuhr: wall(times.dhuhr),
          asr: wall(times.asr),
          maghrib: wall(times.maghrib),
          isha: wall(times.isha),
          fajrTomorrow: wall(times.fajrAfter),
          ishaYesterday: wall(times.ishaBefore),
          sahriSafety: Duration(minutes: params.sahriSafetyMinutes),
        ),
      );
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Prayer time computation failed', e),
      );
    }
  }

  /// Maps domain params to adhan_dart, applying user minute adjustments.
  static adhan.CalculationParameters _calculationParameters(
    PrayerParams params,
  ) {
    final calc = switch (params.method) {
      CalculationMethodId.muslimWorldLeague =>
        adhan.CalculationMethodParameters.muslimWorldLeague(),
      CalculationMethodId.egyptian =>
        adhan.CalculationMethodParameters.egyptian(),
      CalculationMethodId.karachi =>
        adhan.CalculationMethodParameters.karachi(),
      CalculationMethodId.ummAlQura =>
        adhan.CalculationMethodParameters.ummAlQura(),
      CalculationMethodId.dubai => adhan.CalculationMethodParameters.dubai(),
      CalculationMethodId.qatar => adhan.CalculationMethodParameters.qatar(),
      CalculationMethodId.kuwait =>
        adhan.CalculationMethodParameters.kuwait(),
      CalculationMethodId.moonsightingCommittee =>
        adhan.CalculationMethodParameters.moonsightingCommittee(),
      CalculationMethodId.singapore =>
        adhan.CalculationMethodParameters.singapore(),
      CalculationMethodId.northAmerica =>
        adhan.CalculationMethodParameters.northAmerica(),
      CalculationMethodId.turkiye =>
        adhan.CalculationMethodParameters.turkiye(),
      CalculationMethodId.tehran =>
        adhan.CalculationMethodParameters.tehran(),
    };
    // Shafiʿi, Maliki and Hanbali share the standard Asr shadow rule.
    calc.madhab = switch (params.madhab) {
      Madhab.hanafi => adhan.Madhab.hanafi,
      Madhab.shafi || Madhab.maliki || Madhab.hanbali => adhan.Madhab.shafi,
    };
    calc.highLatitudeRule = switch (params.highLatitudeRule) {
      HighLatitudeRule.middleOfTheNight =>
        adhan.HighLatitudeRule.middleOfTheNight,
      HighLatitudeRule.seventhOfTheNight =>
        adhan.HighLatitudeRule.seventhOfTheNight,
      HighLatitudeRule.twilightAngle => adhan.HighLatitudeRule.twilightAngle,
    };
    calc.adjustments = {
      adhan.Prayer.fajr: params.adjustmentFor(Prayer.fajr),
      adhan.Prayer.dhuhr: params.adjustmentFor(Prayer.dhuhr),
      adhan.Prayer.asr: params.adjustmentFor(Prayer.asr),
      adhan.Prayer.maghrib: params.adjustmentFor(Prayer.maghrib),
      adhan.Prayer.isha: params.adjustmentFor(Prayer.isha),
      adhan.Prayer.sunrise: 0,
    };
    return calc;
  }
}
