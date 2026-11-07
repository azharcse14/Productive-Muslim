import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

void main() {
  setUpAll(TimezoneClock.initialize);
  final repo = PrayerDayRepositoryImpl(TimezoneClock());
  final date = DateTime(2026, 6, 12);

  group('PrayerDayRepositoryImpl (adhan_dart, Dhaka 2026-06-12)', () {
    test('times are strictly ordered through the day', () {
      final day = repo
          .prayerDay(location: _dhaka, params: const PrayerParams(), date: date)
          .valueOrNull!;
      final ordered = [
        day.fajr,
        day.sunrise,
        day.dhuhr,
        day.asr,
        day.maghrib,
        day.isha,
        day.fajrTomorrow,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i].isAfter(ordered[i - 1]),
          isTrue,
          reason: '${ordered[i]} should follow ${ordered[i - 1]}',
        );
      }
      expect(day.ishaYesterday.isBefore(day.fajr), isTrue);
    });

    test('wall-clock times are plausible for Dhaka in June', () {
      final day = repo
          .prayerDay(location: _dhaka, params: const PrayerParams(), date: date)
          .valueOrNull!;
      expect(day.fajr.hour, inInclusiveRange(3, 4));
      expect(day.sunrise.hour, inInclusiveRange(5, 6));
      expect(day.dhuhr.hour, inInclusiveRange(11, 12));
      expect(day.maghrib.hour, inInclusiveRange(18, 19));
      expect(day.fajr.day, 12);
    });

    test('hanafi asr is later than shafi asr', () {
      PrayerParams params(Madhab m) => PrayerParams(madhab: m);
      final hanafi = repo
          .prayerDay(
            location: _dhaka,
            params: params(Madhab.hanafi),
            date: date,
          )
          .valueOrNull!;
      final shafi = repo
          .prayerDay(location: _dhaka, params: params(Madhab.shafi), date: date)
          .valueOrNull!;
      expect(hanafi.asr.isAfter(shafi.asr), isTrue);
    });

    test('per-prayer minute adjustments shift only that prayer', () {
      final base = repo
          .prayerDay(location: _dhaka, params: const PrayerParams(), date: date)
          .valueOrNull!;
      final adjusted = repo
          .prayerDay(
            location: _dhaka,
            params: const PrayerParams(adjustments: {Prayer.fajr: 10}),
            date: date,
          )
          .valueOrNull!;
      expect(adjusted.fajr.difference(base.fajr).inMinutes, 10);
      expect(adjusted.dhuhr, base.dhuhr);
      expect(adjusted.maghrib, base.maghrib);
    });

    test('sahri safety margin moves sahri end only', () {
      PrayerDay at(int minutes) => repo
          .prayerDay(
            location: _dhaka,
            params: PrayerParams(sahriSafetyMinutes: minutes),
            date: date,
          )
          .valueOrNull!;
      final none = at(0);
      final three = at(3);
      final ten = at(10);
      // Shown Fajr is rounded up, so a 0 margin still ends sahri a minute
      // early; a real margin is exact (no extra minute on top).
      expect(none.sahriEnd, none.fajr.subtract(const Duration(minutes: 1)));
      expect(three.sahriEnd, none.fajr.subtract(const Duration(minutes: 3)));
      expect(ten.fajr, none.fajr);
      expect(ten.sahriEnd, none.fajr.subtract(const Duration(minutes: 10)));
    });

    test('calculation method changes fajr/isha', () {
      final karachi = repo
          .prayerDay(location: _dhaka, params: const PrayerParams(), date: date)
          .valueOrNull!;
      final uaq = repo
          .prayerDay(
            location: _dhaka,
            params: const PrayerParams(method: CalculationMethodId.ummAlQura),
            date: date,
          )
          .valueOrNull!;
      expect(karachi.fajr, isNot(uaq.fajr));
      // Dhuhr is solar noon — method-independent (±rounding).
      expect(karachi.dhuhr.difference(uaq.dhuhr).inMinutes.abs() <= 1, isTrue);
    });

    test('GPS location yields device-local wall clock without throwing', () {
      const gps = GpsLocation(latitude: 23.7104, longitude: 90.4074);
      final result = repo.prayerDay(
        location: gps,
        params: const PrayerParams(),
        date: date,
      );
      expect(result.isSuccess, isTrue);
    });
  });

  test('London midsummer: Isha follows the rule even when it meets Fajr', () {
    const london = ManualCityLocation(
      City(
        name: 'London',
        countryCode: 'GB',
        latitude: 51.5072,
        longitude: -0.1276,
        timezone: 'Europe/London',
      ),
    );
    final date = DateTime(2026, 6, 21);
    PrayerDay dayWith(HighLatitudeRule rule) => repo
        .prayerDay(
          location: london,
          params: PrayerParams(highLatitudeRule: rule),
          date: date,
        )
        .valueOrNull!;
    final tomorrow = repo
        .prayerDay(
          location: london,
          params: const PrayerParams(),
          date: date.add(const Duration(days: 1)),
        )
        .valueOrNull!;
    // Karachi's 18° is never reached in London in June. Middle-of-the-night
    // puts Isha and Fajr both at mid-night; Isha used to jump to 23:13.
    // Night = sunset → tomorrow's true sunrise.
    final night = tomorrow.trueSunrise
        .add(const Duration(minutes: 1))
        .difference(dayWith(HighLatitudeRule.middleOfTheNight).sunset);
    for (final (rule, share) in [
      (HighLatitudeRule.middleOfTheNight, 1 / 2),
      (HighLatitudeRule.seventhOfTheNight, 1 / 7),
      (HighLatitudeRule.twilightAngle, 18 / 60),
    ]) {
      final day = dayWith(rule);
      final expected = day.sunset.add(night * share);
      expect(
        day.isha.difference(expected).inMinutes.abs() <= 2,
        isTrue,
        reason: '$rule: ${day.isha} vs $expected',
      );
    }
    final middle = dayWith(HighLatitudeRule.middleOfTheNight);
    expect(
      middle.isha,
      middle.fajrTomorrow.subtract(const Duration(minutes: 1)),
    );
  });

  test('London midsummer: adjacent-day Fajr/Isha stay on their own days', () {
    const london = ManualCityLocation(
      City(
        name: 'London',
        countryCode: 'GB',
        latitude: 51.5072,
        longitude: -0.1276,
        timezone: 'Europe/London',
      ),
    );
    for (final rule in HighLatitudeRule.values) {
      final day = repo
          .prayerDay(
            location: london,
            params: PrayerParams(highLatitudeRule: rule),
            date: DateTime(2026, 6, 21),
          )
          .valueOrNull!;
      // adhan's own fajrAfter/ishaBefore returned today's Fajr / tonight's
      // Isha here. (middleOfTheNight puts Isha and Fajr seconds apart.)
      expect(day.fajrTomorrow.isAfter(day.maghrib), isTrue, reason: '$rule');
      expect(day.ishaYesterday.isBefore(day.sunrise), isTrue, reason: '$rule');
    }
  });

  for (final (name, lat, lng, tz, date) in [
    ('Tromsø', 69.6492, 18.9553, 'Europe/Oslo', DateTime(2026, 6, 21)),
    ('Tromsø', 69.6492, 18.9553, 'Europe/Oslo', DateTime(2026, 12, 21)),
    ('Murmansk', 68.9585, 33.0827, 'Europe/Moscow', DateTime(2026, 6, 21)),
    ('Murmansk', 68.9585, 33.0827, 'Europe/Moscow', DateTime(2026, 12, 21)),
    ('Bodø', 67.2804, 14.4049, 'Europe/Oslo', DateTime(2026, 6, 21)),
    ('Bodø', 67.2804, 14.4049, 'Europe/Oslo', DateTime(2026, 12, 21)),
    ('Nome', 64.5011, -165.4064, 'America/Nome', DateTime(2026, 6, 21)),
    ('Nome', 64.5011, -165.4064, 'America/Nome', DateTime(2026, 12, 21)),
  ]) {
    test('polar $name ${date.month}/${date.day}: times sit on that date', () {
      final city = ManualCityLocation(
        City(
          name: name,
          countryCode: 'XX',
          latitude: lat,
          longitude: lng,
          timezone: tz,
        ),
      );
      final day = repo
          .prayerDay(location: city, params: const PrayerParams(), date: date)
          .valueOrNull!;
      // adhan's own polar resolution borrowed times weeks away
      // (Tromsø 21 Jun: sunrise 30 May, maghrib 14 Jul).
      final start = DateTime.utc(date.year, date.month, date.day);
      final dayAfter = start.add(const Duration(days: 2));
      final dayBefore = start.subtract(const Duration(days: 1));
      for (final t in [day.fajr, day.sunrise, day.dhuhr, day.asr]) {
        expect(DateTime.utc(t.year, t.month, t.day), start, reason: '$t');
      }
      for (final t in [day.maghrib, day.sunset, day.isha, day.fajrTomorrow]) {
        expect(
          !t.isBefore(start) && t.isBefore(dayAfter),
          isTrue,
          reason: '$t',
        );
      }
      for (final t in [
        day.ishaYesterday,
        day.maghribYesterday!,
        day.asrYesterday!,
      ]) {
        expect(
          !t.isBefore(dayBefore) &&
              t.isBefore(start.add(const Duration(days: 1))),
          isTrue,
          reason: '$t',
        );
      }
      final ordered = [day.fajr, day.sunrise, day.dhuhr, day.asr, day.maghrib];
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i].isAfter(ordered[i - 1]), isTrue, reason: '$ordered');
      }
      // Rounding once put Isha a minute past the next Fajr (Tromsø 21 Jun:
      // 00:47 vs 00:46; Nome: both 03:04).
      expect(day.isha.isBefore(day.fajrTomorrow), isTrue, reason: '$day');
      expect(day.ishaYesterday.isBefore(day.fajr), isTrue, reason: '$day');
    });
  }

  group('high-latitude rule: 45° proportion (MWL)', () {
    const rule = PrayerParams(
      method: CalculationMethodId.muslimWorldLeague,
      highLatitudeRule: HighLatitudeRule.latitude45Proportion,
    );
    final june = DateTime(2026, 6, 21);
    ManualCityLocation city(double lat, double lng, String tz) =>
        ManualCityLocation(
          City(
            name: 'X',
            countryCode: 'XX',
            latitude: lat,
            longitude: lng,
            timezone: tz,
          ),
        );

    // The formula, straight from adhan: unrounded, unadjusted times.
    adhan.PrayerTimes raw(double lat, double lng, int day) => adhan.PrayerTimes(
      date: DateTime.utc(2026, 6, day, 12),
      coordinates: adhan.Coordinates(lat, lng),
      calculationParameters:
          adhan.CalculationMethodParameters.muslimWorldLeague()
            ..methodAdjustments = {},
      precision: true,
    );
    DateTime upToMinute(DateTime t) {
      final s = t.add(const Duration(seconds: 59));
      return DateTime.utc(s.year, s.month, s.day, s.hour, s.minute);
    }

    for (final (name, lat, lng, tz) in [
      ('London', 51.5072, -0.1276, 'Europe/London'),
      ('Oslo', 59.9139, 10.7522, 'Europe/Oslo'),
    ]) {
      test('$name in June: Isha/Fajr follow the 45° share of the night', () {
        final loc = city(lat, lng, tz);
        final day = repo
            .prayerDay(location: loc, params: rule, date: june)
            .valueOrNull!;
        final [h20, h21, h22] = [
          for (final d in [20, 21, 22]) raw(lat, lng, d),
        ];
        final [f20, f21, f22] = [
          for (final d in [20, 21, 22]) raw(45, lng, d),
        ];
        double share(Duration part, Duration night) =>
            part.inMicroseconds / night.inMicroseconds;
        final tonight = h22.sunrise.difference(h21.sunset);
        final lastNight = h21.sunrise.difference(h20.sunset);
        final isha = h21.sunset.add(
          tonight *
              share(
                f21.isha.difference(f21.sunset),
                f22.sunrise.difference(f21.sunset),
              ),
        );
        final fajr = h21.sunrise.subtract(
          lastNight *
              share(
                f21.sunrise.difference(f21.fajr),
                f21.sunrise.difference(f20.sunset),
              ),
        );
        final clock = TimezoneClock();
        expect(day.isha, clock.instantAt(loc, upToMinute(isha)));
        expect(day.fajr, clock.instantAt(loc, upToMinute(fajr)));

        final middle = repo
            .prayerDay(
              location: loc,
              params: rule.copyWith(
                highLatitudeRule: HighLatitudeRule.middleOfTheNight,
              ),
              date: june,
            )
            .valueOrNull!;
        expect(day.isha, isNot(middle.isha));
        expect(day.fajr, isNot(middle.fajr));
        expect(day.ishaYesterday, isNot(middle.ishaYesterday));
        expect(day.fajrTomorrow, isNot(middle.fajrTomorrow));
        expect(day.maghrib, middle.maghrib);

        // User minute adjustments still apply on top.
        final adjusted = repo
            .prayerDay(
              location: loc,
              params: rule.copyWith(
                adjustments: {Prayer.isha: 5, Prayer.fajr: -3},
              ),
              date: june,
            )
            .valueOrNull!;
        expect(adjusted.isha, day.isha.add(const Duration(minutes: 5)));
        expect(adjusted.fajr, day.fajr.subtract(const Duration(minutes: 3)));
      });
    }

    test('at 45° the rule changes nothing', () {
      final loc = city(45, 10, 'Europe/Rome');
      for (final date in [june, DateTime(2026, 12, 21)]) {
        PrayerDay at(HighLatitudeRule r) => repo
            .prayerDay(
              location: loc,
              params: rule.copyWith(highLatitudeRule: r),
              date: date,
            )
            .valueOrNull!;
        final a = at(HighLatitudeRule.latitude45Proportion);
        final b = at(HighLatitudeRule.middleOfTheNight);
        expect(
          [a.ishaYesterday, a.fajr, a.isha, a.fajrTomorrow],
          [b.ishaYesterday, b.fajr, b.isha, b.fajrTomorrow],
        );
      }
    });
  });

  test('polar rule 45°: above 66° every time is the 45° analogue', () {
    ManualCityLocation at(double lat) => ManualCityLocation(
      City(
        name: 'Tromsø',
        countryCode: 'NO',
        latitude: lat,
        longitude: 18.9553,
        timezone: 'Europe/Oslo',
      ),
    );
    const lat45 = PrayerParams(polarRule: PolarRule.latitude45);
    for (final date in [DateTime(2026, 6, 21), DateTime(2026, 12, 21)]) {
      final tromso = repo
          .prayerDay(location: at(69.6492), params: lat45, date: date)
          .valueOrNull!;
      final at45 = repo
          .prayerDay(location: at(45), params: const PrayerParams(), date: date)
          .valueOrNull!;
      final nearest = repo
          .prayerDay(
            location: at(69.6492),
            params: const PrayerParams(),
            date: date,
          )
          .valueOrNull!;
      expect(
        [
          tromso.fajr,
          tromso.sunrise,
          tromso.dhuhr,
          tromso.maghrib,
          tromso.isha,
        ],
        [at45.fajr, at45.sunrise, at45.dhuhr, at45.maghrib, at45.isha],
      );
      expect(tromso.maghrib, isNot(nearest.maghrib));
    }
    // Below 66° the 45° rule changes nothing.
    final below = repo
        .prayerDay(location: at(60), params: lat45, date: DateTime(2026, 3, 2))
        .valueOrNull!;
    final belowDefault = repo
        .prayerDay(
          location: at(60),
          params: const PrayerParams(),
          date: DateTime(2026, 3, 2),
        )
        .valueOrNull!;
    expect(below.maghrib, belowDefault.maghrib);
  });

  test('raw transit ignores the user Dhuhr adjustment', () {
    final day = repo
        .prayerDay(
          location: _dhaka,
          params: const PrayerParams(adjustments: {Prayer.dhuhr: 10}),
          date: date,
        )
        .valueOrNull!;
    final plain = repo
        .prayerDay(location: _dhaka, params: const PrayerParams(), date: date)
        .valueOrNull!;
    expect(day.dhuhr, plain.dhuhr.add(const Duration(minutes: 10)));
    expect(day.transit, plain.transit);
    // MWL's own +1 min Dhuhr offset is left out too.
    expect(plain.dhuhr.difference(plain.transit), const Duration(minutes: 1));
  });

  test("Nome in June: yesterday's asr runs past midnight", () {
    const nome = ManualCityLocation(
      City(
        name: 'Nome',
        countryCode: 'US',
        latitude: 64.5011,
        longitude: -165.4064,
        timezone: 'America/Nome',
      ),
    );
    final day = repo
        .prayerDay(
          location: nome,
          params: const PrayerParams(),
          date: DateTime(2026, 6, 21),
        )
        .valueOrNull!;
    final night = DateTime.utc(2026, 6, 21, 0, 30);
    expect(day.maghribYesterday!.isAfter(night), isTrue);
    expect(day.activeWaqtAt(night)?.prayer, Prayer.asr);
  });

  for (final (name, lat, lng, tz) in [
    ('Apia', -13.83, -171.76, 'Pacific/Apia'), // UTC+13
    ('Kiritimati', 1.87, -157.43, 'Pacific/Kiritimati'), // UTC+14
    ('Honolulu', 21.31, -157.86, 'Pacific/Honolulu'), // UTC−10
    ('Auckland', -36.85, 174.76, 'Pacific/Auckland'), // UTC+12/13
  ]) {
    test('$name: every time of the day falls on that local date', () {
      final city = ManualCityLocation(
        City(
          name: name,
          countryCode: 'XX',
          latitude: lat,
          longitude: lng,
          timezone: tz,
        ),
      );
      final d = DateTime(2026, 3, 10);
      final day = repo
          .prayerDay(location: city, params: const PrayerParams(), date: d)
          .valueOrNull!;
      for (final t in [
        day.fajr,
        day.sunrise,
        day.dhuhr,
        day.asr,
        day.maghrib,
      ]) {
        expect((t.year, t.month, t.day), (2026, 3, 10), reason: '$t');
      }
      expect(day.fajrTomorrow.day, 11);
      expect(day.ishaYesterday.day, 9);
    });
  }

  test('times are whole minutes', () {
    final day = repo
        .prayerDay(location: _dhaka, params: const PrayerParams(), date: date)
        .valueOrNull!;
    for (final t in [day.fajr, day.maghrib, day.isha]) {
      expect((t.second, t.millisecond), (0, 0));
    }
  });

  test('Umm al-Qura: Isha is 30 min later in Ramadan', () {
    const params = PrayerParams(method: CalculationMethodId.ummAlQura);
    Duration gap(DateTime d) {
      final day = repo
          .prayerDay(location: _dhaka, params: params, date: d)
          .valueOrNull!;
      return day.isha.difference(day.maghrib);
    }

    // 2026-03-02 is in Ramadan 1447; 2026-04-02 is not.
    expect(gap(DateTime(2026, 3, 2)), const Duration(minutes: 120));
    expect(gap(DateTime(2026, 4, 2)), const Duration(minutes: 90));
  });

  test('Umm al-Qura: the Ramadan Isha follows the Hijri day turning at '
      'Maghrib', () {
    const params = PrayerParams(method: CalculationMethodId.ummAlQura);
    Duration gap(DateTime d) {
      final day = repo
          .prayerDay(location: _dhaka, params: params, date: d)
          .valueOrNull!;
      return day.isha.difference(day.maghrib);
    }

    final first = const HijriDate(1447, 9, 1).toGregorian();
    final eid = const HijriDate(1447, 10, 1).toGregorian();
    DateTime civil(DateTime d, int plus) =>
        DateTime(d.year, d.month, d.day + plus);
    // The evening before 1 Ramadan is its first night (Taraweeh).
    expect(gap(civil(first, -2)), const Duration(minutes: 90));
    expect(gap(civil(first, -1)), const Duration(minutes: 120));
    // The evening of the last fast is Eid night.
    expect(gap(civil(eid, -2)), const Duration(minutes: 120));
    expect(gap(civil(eid, -1)), const Duration(minutes: 90));
  });

  // Day D's tonight is day D+1's last night: both must be the same times.
  void expectConsecutiveAgree(PrayerDay d, PrayerDay next, String why) {
    expect(d.fajrTomorrow, next.fajr, reason: 'fajr $why');
    expect(d.isha, next.ishaYesterday, reason: 'isha $why');
    expect(d.maghrib, next.maghribYesterday, reason: 'maghrib $why');
    expect(d.sunset, next.sunsetYesterday, reason: 'sunset $why');
    expect(d.asr, next.asrYesterday, reason: 'asr $why');
  }

  ManualCityLocation place(String name, double lat, double lng, String tz) =>
      ManualCityLocation(
        City(
          name: name,
          countryCode: 'XX',
          latitude: lat,
          longitude: lng,
          timezone: tz,
        ),
      );
  final suva = place('Suva', -18.1416, 178.4419, 'Pacific/Fiji');

  test('Suva 19-21 Sep: noon crossing UTC midnight keeps each day its own '
      'times', () {
    final days = [
      for (final d in [19, 20, 21])
        repo
            .prayerDay(
              location: suva,
              params: const PrayerParams(),
              date: DateTime(2026, 9, d),
            )
            .valueOrNull!,
    ];
    for (final (i, day) in days.indexed) {
      expect(day.dhuhr.day, 19 + i, reason: '${day.dhuhr}');
      expect(day.fajr.day, 19 + i, reason: '${day.fajr}');
    }
    expect(days[0].fajrTomorrow.day, 20);
    expect(days[2].ishaYesterday.day, 20);
    expectConsecutiveAgree(days[0], days[1], '19→20');
    expectConsecutiveAgree(days[1], days[2], '20→21');
  });

  for (final (loc, params) in [
    (suva, const PrayerParams()),
    (
      place('Funafuti', -8.5211, 179.1983, 'Pacific/Funafuti'),
      const PrayerParams(),
    ),
    (place('Anadyr', 64.7337, 177.4968, 'Asia/Anadyr'), const PrayerParams()),
    (
      place('Chatham', -43.9535, -176.5597, 'Pacific/Chatham'),
      const PrayerParams(),
    ),
    (_dhaka, const PrayerParams()),
    (
      place('Tromsø', 69.6492, 18.9553, 'Europe/Oslo'),
      const PrayerParams(
        method: CalculationMethodId.muslimWorldLeague,
        highLatitudeRule: HighLatitudeRule.latitude45Proportion,
      ),
    ),
    (
      place('Tromsø', 69.6492, 18.9553, 'Europe/Oslo'),
      const PrayerParams(
        method: CalculationMethodId.moonsightingCommittee,
        highLatitudeRule: HighLatitudeRule.latitude45Proportion,
      ),
    ),
  ]) {
    test('${loc.city.name} ${params.method.name}: consecutive days agree all '
        'year', () {
      PrayerDay on(int i) => repo
          .prayerDay(location: loc, params: params, date: DateTime(2026, 1, i))
          .valueOrNull!;
      var day = on(1);
      for (var i = 2; i <= 366; i++) {
        final next = on(i);
        final d = DateTime(2026, 1, i - 1);
        expect(
          (day.dhuhr.month, day.dhuhr.day),
          (d.month, d.day),
          reason: '$d',
        );
        expectConsecutiveAgree(day, next, '$d');
        day = next;
      }
    });
  }
}
