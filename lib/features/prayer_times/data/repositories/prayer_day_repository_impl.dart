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
      // the sun rises and sets (aqrab al-bilad).
      final baseLatitude =
          params.polarRule == PolarRule.latitude45 &&
              location.latitude.abs() >= 66
          ? 45.0 * location.latitude.sign
          : location.latitude;
      final offset = _hijriOffset();
      // Per day −1, 0, +1 (index d + 1), each a function of that civil date
      // alone: day D's tonight and day D+1's last night are then the same
      // computation, whichever day is requested.
      // [shifts]: adhan computes the solar day of a UTC date. Where the
      // zone runs a day ahead of solar time (Samoa, UTC+13 at 172°W) that
      // day's times land on the next local date; near 180° the equation of
      // time moves noon across UTC midnight on one date a year (Suva 20
      // Sep). Each day takes the solar day whose Dhuhr lands on it.
      // [nudges]: on that date one UTC day holds two transits and adhan
      // (transit normalised into its UTC day) only ever yields the first:
      // computed 1° east the transit sits 4 min before midnight, and the
      // times are moved back 4 min (sub-second error).
      // [latitudes]: each day's own stepped latitude, never its
      // neighbours' (a shared stepping made the result depend on the day
      // requested: Tromsø 4 Jan, Fajr 08:22 vs 07:54).
      final shifts = [0, 0, 0];
      final nudges = [0, 0, 0];
      final latitudes = [baseLatitude, baseLatitude, baseLatitude];
      // Whole minutes, rounded up: the displayed (minute-only) time, the
      // countdown and the notification then agree, and never run early.
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
        final nudge = nudges[dayOffset + 1];
        // Wrapped into adhan's ±180° (it works modulo 360°).
        final lng = location.longitude + nudge;
        final t = adhan.PrayerTimes(
          date: day.add(Duration(days: shifts[dayOffset + 1])),
          coordinates: adhan.Coordinates(
            lat ?? latitudes[dayOffset + 1],
            lng > 180 ? lng - 360 : lng,
          ),
          calculationParameters: calc,
          precision: raw,
        );
        if (nudge == 0) return t;
        final back = Duration(minutes: 4 * nudge);
        return t
          ..fajr = t.fajr.add(back)
          ..sunrise = t.sunrise.add(back)
          ..dhuhr = t.dhuhr.add(back)
          ..asr = t.asr.add(back)
          ..sunset = t.sunset.add(back)
          ..maghrib = t.maghrib.add(back)
          ..isha = t.isha.add(back);
      }

      DateTime wall(DateTime utc) => _clock.instantAt(location, utc);
      final near = <adhan.PrayerTimes>[];
      for (final d in const [-1, 0, 1]) {
        final i = d + 1;
        final target = DateTime.utc(date.year, date.month, date.day + d);
        bool lands() {
          final noon = wall(timesOn(d).dhuhr);
          return DateTime.utc(noon.year, noon.month, noon.day) == target;
        }

        search:
        for (final nudge in const [0, 1]) {
          for (final shift in const [0, -1, 1]) {
            nudges[i] = nudge;
            shifts[i] = shift;
            if (lands()) break search;
            nudges[i] = shifts[i] = 0;
          }
        }
        var t = timesOn(d);
        // adhan_dart 2.0.1 never yields NaN where the sun doesn't rise or
        // set (its own polarCircleResolution never fires): it returns times
        // weeks away instead. Same 0.5° step as adhan's aqrabBalad.
        while (!_sunRisesAndSets(t) && latitudes[d + 1].abs() > 60) {
          latitudes[d + 1] -= latitudes[d + 1].sign * 0.5;
          t = timesOn(d);
        }
        near.add(t);
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
          baseLatitude.abs() > 45) {
        final here = [
          for (final d in const [-1, 0, 1]) timesOn(d, raw: true),
        ];
        final at45 = [
          for (final d in const [-1, 0, 1])
            timesOn(d, lat: 45.0 * baseLatitude.sign, raw: true),
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
        // Night n is judged at the latitude of the day it starts on.
        bool reached(double angle, int n) => _twilightReached(
          latitudes[n],
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
          // Shown Fajr is rounded *up* (up to 59 s after true Fajr), so a
          // 0 margin still takes 1 min off: sahri never ends after true
          // Fajr. A margin of m >= 1 already covers that, so sahri shows
          // exactly m min before the shown Fajr (BD: 3, as IFB prints it).
          sahriSafety: Duration(
            minutes: params.sahriSafetyMinutes < 1
                ? 1
                : params.sahriSafetyMinutes,
          ),
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
