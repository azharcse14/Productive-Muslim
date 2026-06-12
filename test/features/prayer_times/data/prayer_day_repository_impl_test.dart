import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:qalbee/features/settings/data/datasources/timezone_clock.dart';
import 'package:qalbee/features/settings/domain/entities/city.dart';
import 'package:qalbee/features/settings/domain/entities/location_config.dart';
import 'package:qalbee/features/settings/domain/entities/prayer_params.dart';

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
          .prayerDay(
            location: _dhaka,
            params: const PrayerParams(),
            date: date,
          )
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
        expect(ordered[i].isAfter(ordered[i - 1]), isTrue,
            reason: '${ordered[i]} should follow ${ordered[i - 1]}');
      }
      expect(day.ishaYesterday.isBefore(day.fajr), isTrue);
    });

    test('wall-clock times are plausible for Dhaka in June', () {
      final day = repo
          .prayerDay(
            location: _dhaka,
            params: const PrayerParams(),
            date: date,
          )
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
          .prayerDay(location: _dhaka, params: params(Madhab.hanafi), date: date)
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

    test('calculation method changes fajr/isha', () {
      final karachi = repo
          .prayerDay(
            location: _dhaka,
            params: const PrayerParams(),
            date: date,
          )
          .valueOrNull!;
      final uaq = repo
          .prayerDay(
            location: _dhaka,
            params:
                const PrayerParams(method: CalculationMethodId.ummAlQura),
            date: date,
          )
          .valueOrNull!;
      expect(karachi.fajr, isNot(uaq.fajr));
      // Dhuhr is solar noon — method-independent (±rounding).
      expect(
        karachi.dhuhr.difference(uaq.dhuhr).inMinutes.abs() <= 1,
        isTrue,
      );
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
}
