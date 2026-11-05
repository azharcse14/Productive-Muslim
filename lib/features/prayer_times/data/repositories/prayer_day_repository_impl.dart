import 'dart:math';

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
      // Polar day/night: either 45° above the polar circle (MWL Fiqh
      // Council region 3) or, by default, stepped toward the equator until
      // the sun rises and sets on all three days used (aqrab al-bilad).
      var latitude =
          params.polarRule == PolarRule.latitude45 &&
              location.latitude.abs() >= 66
          ? 45.0 * location.latitude.sign
          : location.latitude;
      final offset = _hijriOffset();
      // Whole minutes, rounded up: the displayed (minute-only) time, the
      // countdown and the notification then agree, and never run early.
      // adhan computes the solar day of a UTC date. Where the zone runs a
      // day ahead of solar time (Samoa, UTC+13 at 172°W) that day's times
      // land on the next local date: [shift] picks the matching solar day.
      var shift = 0;
      // [raw]: unadjusted, unrounded times (the 45° proportion's inputs).
      adhan.PrayerTimes timesOn(
        int dayOffset, {
        double? lat,
        bool raw = false,
      }) {
        final day = DateTime.utc(
          date.year,
          date.month,
          date.day + dayOffset,
          12,
        );
        // Only Isha depends on it, and Isha comes after Maghrib, when the
        // Hijri day has already turned: ask about the next civil day.
        final ramadan =
            HijriDate.fromGregorian(
              day.add(const Duration(days: 1)),
              offsetDays: offset,
            ).month ==
            HijriDate.ramadanMonth;
        final calc = _calculationParameters(params, ramadan);
        if (raw) {
          calc
            ..adjustments = {}
            ..methodAdjustments = {};
        }
        return adhan.PrayerTimes(
          date: day.add(Duration(days: shift)),
          coordinates: adhan.Coordinates(lat ?? latitude, location.longitude),
          calculationParameters: calc,
          precision: raw,
        );
      }

      DateTime wall(DateTime utc) => _clock.instantAt(location, utc);
      final noon = wall(timesOn(0).dhuhr);
      shift = DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime.utc(noon.year, noon.month, noon.day)).inDays;

      List<adhan.PrayerTimes> around() => [
        for (final d in const [-1, 0, 1]) timesOn(d),
      ];
      var near = around();
      // adhan_dart 2.0.1 never yields NaN where the sun doesn't rise or set
      // (its own polarCircleResolution never fires): it returns times weeks
      // away instead. Same 0.5° step as adhan's aqrabBalad.
      while (!near.every(_sunRisesAndSets) && latitude.abs() > 60) {
        latitude -= latitude.sign * 0.5;
        near = around();
      }
      final [yesterday, times, tomorrow] = near;
      // Fajr ends at the method's sunrise; the makruh window uses the sun's.
      final calc = _calculationParameters(params, false);
      final methodOffsets = calc.methodAdjustments;
      final sunriseOffset = methodOffsets[adhan.Prayer.sunrise] ?? 0;
      // Dhuhr minus every minute offset: the sun's own transit.
      final dhuhrOffset =
          (methodOffsets[adhan.Prayer.dhuhr] ?? 0) +
          params.adjustmentFor(Prayer.dhuhr);

      var ishaYesterday = yesterday.isha;
      var fajr = times.fajr;
      var isha = times.isha;
      var fajrTomorrow = tomorrow.fajr;
      // MWL Fiqh Council, 9th session (1406 AH), region 2: Isha and Fajr
      // take the share of the night they take at 45°. Like adhan's own
      // rules, only a bound: Isha no later, Fajr no earlier.
      if (params.highLatitudeRule == HighLatitudeRule.latitude45Proportion &&
          latitude.abs() > 45) {
        final here = [
          for (final d in const [-1, 0, 1]) timesOn(d, raw: true),
        ];
        final at45 = [
          for (final d in const [-1, 0, 1])
            timesOn(d, lat: 45.0 * latitude.sign, raw: true),
        ];
        // Night n (0: last night, 1: tonight): sunset of day n-1 → sunrise
        // of day n, as indexes into [-1, 0, 1].
        Duration night(List<adhan.PrayerTimes> t, int n) =>
            t[n + 1].sunrise.difference(t[n].sunset);
        DateTime proportional(adhan.Prayer prayer, int n) {
          final part = prayer == adhan.Prayer.isha
              ? at45[n].isha.difference(at45[n].sunset)
              : at45[n + 1].sunrise.difference(at45[n + 1].fajr);
          final offset =
              night(here, n) *
              (part.inMicroseconds / night(at45, n).inMicroseconds);
          final raw = prayer == adhan.Prayer.isha
              ? here[n].sunset.add(offset)
              : here[n + 1].sunrise.subtract(offset);
          final minutes =
              (calc.adjustments[prayer] ?? 0) +
              (calc.methodAdjustments[prayer] ?? 0);
          return _roundUp(raw.add(Duration(minutes: minutes)));
        }

        // Where the twilight angle is never reached adhan returns an
        // arbitrary time, not NaN: the proportion replaces it outright.
        bool reached(double angle, int n) => _twilightReached(
          latitude,
          angle,
          here[n].sunset.add(night(here, n) ~/ 2),
        );
        DateTime earlier(DateTime a, DateTime b) => b.isBefore(a) ? b : a;
        DateTime later(DateTime a, DateTime b) => b.isAfter(a) ? b : a;
        DateTime ishaOf(DateTime computed, int n) {
          final p = proportional(adhan.Prayer.isha, n);
          return reached(calc.ishaAngle, n) ? earlier(computed, p) : p;
        }

        DateTime fajrOf(DateTime computed, int n) {
          final p = proportional(adhan.Prayer.fajr, n);
          return reached(calc.fajrAngle, n) ? later(computed, p) : p;
        }

        // Interval methods (Umm al-Qura) fix Isha after Maghrib; adhan
        // never bounds those either.
        if ((calc.ishaInterval ?? 0) == 0) {
          ishaYesterday = ishaOf(ishaYesterday, 0);
          isha = ishaOf(isha, 1);
        }
        fajr = fajrOf(fajr, 0);
        fajrTomorrow = fajrOf(fajrTomorrow, 1);
      }
      // Near the polar edge middle-of-the-night Isha and the next Fajr come
      // from different nights: rounding can put Isha at or past that Fajr
      // (Tromsø 21 Jun: 00:47 vs 00:46), and where twilight never ends the
      // rule puts both at mid-night (London in June). Isha then starts a
      // minute before that Fajr — never before the Maghrib→Fajr midpoint.
      DateTime beforeFajr(DateTime isha, DateTime maghrib, DateTime fajr) {
        if (isha.isBefore(fajr)) return isha;
        final justBefore = fajr.subtract(const Duration(minutes: 1));
        final midpoint = _roundUp(maghrib.add(fajr.difference(maghrib) ~/ 2));
        return justBefore.isAfter(midpoint) ? justBefore : midpoint;
      }

      ishaYesterday = beforeFajr(ishaYesterday, yesterday.maghrib, fajr);
      isha = beforeFajr(isha, times.maghrib, fajrTomorrow);

      return Result.success(
        PrayerDay(
          fajr: wall(fajr),
          // Rounded *up* like the rest, but sunrise ends Fajr: take a
          // minute off so Fajr never shows as running past true sunrise.
          sunrise: wall(times.sunrise).subtract(const Duration(minutes: 1)),
          trueSunrise: wall(
            times.sunrise,
          ).subtract(Duration(minutes: 1 + sunriseOffset)),
          sunset: wall(times.sunset),
          sunsetYesterday: wall(yesterday.sunset),
          dhuhr: wall(times.dhuhr),
          transit: wall(times.dhuhr).subtract(Duration(minutes: dhuhrOffset)),
          asr: wall(times.asr),
          maghrib: wall(times.maghrib),
          isha: wall(isha),
          // Not adhan's fajrAfter/ishaBefore: when twilight is never
          // reached (high-latitude summer) those return *today's* times.
          fajrTomorrow: wall(fajrTomorrow),
          ishaYesterday: wall(ishaYesterday),
          maghribYesterday: wall(yesterday.maghrib),
          asrYesterday: wall(yesterday.asr),
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
      // Applied by [prayerDay]. adhan's loosest bound: it only clamps Isha
      // to, and Fajr from, mid-night, and the 45° share is always under
      // half a night, so the proportion's own bound always wins.
      HighLatitudeRule.latitude45Proportion =>
        adhan.HighLatitudeRule.middleOfTheNight,
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
    return calc;
  }

  /// Whether the sun sinks [angle]° below the horizon around [midnight]:
  /// its lowest altitude there is |lat| + declination (toward that pole)
  /// − 90°. ponytail: Spencer's declination (±0.04°) and a 0.1° margin —
  /// right at the edge the twilight counts as unreached; take adhan's own
  /// solar coordinates if they're ever exported.
  static bool _twilightReached(double lat, double angle, DateTime midnight) {
    final g =
        2 *
        pi *
        midnight.difference(DateTime.utc(midnight.year)).inMinutes /
        (365 * 24 * 60);
    final declination =
        (0.006918 -
            0.399912 * cos(g) +
            0.070257 * sin(g) -
            0.006758 * cos(2 * g) +
            0.000907 * sin(2 * g) -
            0.002697 * cos(3 * g) +
            0.00148 * sin(3 * g)) *
        180 /
        pi;
    return lat.abs() + declination * lat.sign < 90 - angle - 0.1;
  }

  /// Up to the next whole minute, like adhan's [adhan.Rounding.up].
  static DateTime _roundUp(DateTime t) {
    const minute = Duration.microsecondsPerMinute;
    final us = t.microsecondsSinceEpoch + minute - 1;
    return DateTime.fromMicrosecondsSinceEpoch(us - us % minute, isUtc: true);
  }

  /// False for the garbage adhan returns on a polar day or night: the
  /// times out of order, or sunrise to sunset a day or more.
  static bool _sunRisesAndSets(adhan.PrayerTimes t) =>
      t.fajr.isBefore(t.sunrise) &&
      t.sunrise.isBefore(t.dhuhr) &&
      t.dhuhr.isBefore(t.asr) &&
      t.asr.isBefore(t.sunset) &&
      t.sunset.isBefore(t.isha) &&
      t.sunset.difference(t.sunrise) < const Duration(days: 1);
}
