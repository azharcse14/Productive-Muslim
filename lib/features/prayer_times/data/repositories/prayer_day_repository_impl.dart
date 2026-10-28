import 'package:adhan_dart/adhan_dart.dart' as adhan;

import '../../../../core/utils/hijri_date.dart';
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
  const PrayerDayRepositoryImpl(this._clock, {int Function()? hijriOffset})
    : _hijriOffset = hijriOffset ?? _noOffset;

  final ZonedClock _clock;

  /// The user's Hijri offset (decides which days are Ramadan).
  final int Function() _hijriOffset;

  static int _noOffset() => 0;

  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) {
    try {
      final coordinates = adhan.Coordinates(
        location.latitude,
        location.longitude,
      );
      final offset = _hijriOffset();
      // Whole minutes, rounded up: the displayed (minute-only) time, the
      // countdown and the notification then agree, and never run early.
      adhan.PrayerTimes timesOn(int dayOffset) {
        final day = DateTime.utc(
          date.year,
          date.month,
          date.day + dayOffset,
          12,
        );
        final ramadan =
            HijriDate.fromGregorian(day, offsetDays: offset).month ==
            HijriDate.ramadanMonth;
        return adhan.PrayerTimes(
          date: day,
          coordinates: coordinates,
          calculationParameters: _calculationParameters(params, ramadan),
        );
      }

      final times = timesOn(0);
      final yesterday = timesOn(-1);

      DateTime wall(DateTime utc) => _clock.instantAt(location, utc);

      return Result.success(
        PrayerDay(
          fajr: wall(times.fajr),
          // Rounded *up* like the rest, but sunrise ends Fajr: take a
          // minute off so Fajr never shows as running past true sunrise.
          sunrise: wall(times.sunrise).subtract(const Duration(minutes: 1)),
          dhuhr: wall(times.dhuhr),
          asr: wall(times.asr),
          maghrib: wall(times.maghrib),
          isha: wall(times.isha),
          // Not adhan's fajrAfter/ishaBefore: when twilight is never
          // reached (high-latitude summer) those return *today's* times.
          fajrTomorrow: wall(timesOn(1).fajr),
          ishaYesterday: wall(yesterday.isha),
          maghribYesterday: wall(yesterday.maghrib),
          // +1: times are rounded *up*, so the shown Fajr can be up to 59 s
          // after the true one; sahri must never end after true Fajr.
          sahriSafety: Duration(minutes: params.sahriSafetyMinutes + 1),
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
    bool ramadan,
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
      CalculationMethodId.kuwait => adhan.CalculationMethodParameters.kuwait(),
      CalculationMethodId.moonsightingCommittee =>
        adhan.CalculationMethodParameters.moonsightingCommittee(),
      CalculationMethodId.singapore =>
        adhan.CalculationMethodParameters.singapore(),
      CalculationMethodId.northAmerica =>
        adhan.CalculationMethodParameters.northAmerica(),
      CalculationMethodId.turkiye =>
        adhan.CalculationMethodParameters.turkiye(),
      CalculationMethodId.tehran => adhan.CalculationMethodParameters.tehran(),
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
      // Umm al-Qura's Isha is 90 min after Maghrib, 120 in Ramadan.
      adhan.Prayer.isha:
          params.adjustmentFor(Prayer.isha) +
          (ramadan && params.method == CalculationMethodId.ummAlQura ? 30 : 0),
      adhan.Prayer.sunrise: 0,
    };
    calc.rounding = adhan.Rounding.up;
    // Without it adhan throws on the NaN sunrise/sunset of polar days and
    // nights; take the nearest day that has them.
    calc.polarCircleResolution = adhan.PolarCircleResolution.aqrabYaum;
    return calc;
  }
}
