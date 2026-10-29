import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:timezone/timezone.dart' as tz;

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

const _london = ManualCityLocation(
  City(
    name: 'London',
    countryCode: 'GB',
    latitude: 51.5085,
    longitude: -0.1257,
    timezone: 'Europe/London',
  ),
);

void main() {
  setUpAll(TimezoneClock.initialize);
  final clock = TimezoneClock();

  test('every bundled city zone resolves (aliases included)', () {
    final rows =
        jsonDecode(File('assets/data/cities.json').readAsStringSync())
            as List<dynamic>;
    final zones = {for (final r in rows) (r as List<dynamic>)[4] as String};
    final missing = [
      for (final z in zones)
        if (!tz.timeZoneDatabase.locations.containsKey(z)) z,
    ];
    expect(missing, isEmpty);
  });

  group('TimezoneClock — manual city wall clocks (guide §5)', () {
    test('converts a UTC instant to Dhaka time (UTC+6, no DST)', () {
      final utc = DateTime.utc(2026, 6, 12, 12);
      final local = clock.instantAt(_dhaka, utc);
      expect(local.hour, 18);
      expect(local.day, 12);
    });

    test('handles DST — London is UTC+1 in June, UTC+0 in January', () {
      expect(clock.instantAt(_london, DateTime.utc(2026, 6, 12, 12)).hour, 13);
      expect(clock.instantAt(_london, DateTime.utc(2026, 1, 12, 12)).hour, 12);
    });

    test('crosses the date line correctly', () {
      final utc = DateTime.utc(2026, 6, 12, 23);
      final dhaka = clock.instantAt(_dhaka, utc);
      expect(dhaka.day, 13);
      expect(dhaka.hour, 5);
    });

    test('non-UTC input is normalized before conversion', () {
      final utc = DateTime.utc(2026, 6, 12, 12);
      final viaLocal = clock.instantAt(_dhaka, utc.toLocal());
      expect(viaLocal, clock.instantAt(_dhaka, utc));
    });

    test('GPS locations use the device-local zone', () {
      const gps = GpsLocation(latitude: 0, longitude: 0);
      final utc = DateTime.utc(2026, 6, 12, 12);
      expect(clock.instantAt(gps, utc), utc.toLocal());
    });
  });
}
