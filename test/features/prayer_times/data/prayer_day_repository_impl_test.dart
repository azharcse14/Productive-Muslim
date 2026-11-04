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
      final ten = at(10);
      // Shown Fajr is rounded up, so sahri always ends a minute earlier.
      expect(none.sahriEnd, none.fajr.subtract(const Duration(minutes: 1)));
      expect(ten.fajr, none.fajr);
      expect(ten.sahriEnd, none.fajr.subtract(const Duration(minutes: 11)));
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
    });
  }

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
}
