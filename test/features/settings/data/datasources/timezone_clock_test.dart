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
      final local = utc.toLocal();
      expect(
        clock.instantAt(gps, utc),
        DateTime.utc(local.year, local.month, local.day, local.hour),
      );
    });
  });

  // A manual city's wall time must never pass through the device zone: run
  // this file with `TZ=America/New_York` to exercise the device's own
  // spring-forward gap (02:00–03:00 on 8 Mar 2026) and fall-back hour
  // (01:00–02:00 twice on 1 Nov 2026).
  group('TimezoneClock — floating wall times (device DST immune)', () {
    test('Dhaka 02:30 on the US spring-forward day keeps its fields', () {
      // 20:30 UTC on 7 Mar = 02:30 on 8 Mar in Dhaka.
      final wall = clock.instantAt(_dhaka, DateTime.utc(2026, 3, 7, 20, 30));
      expect(wall, DateTime.utc(2026, 3, 8, 2, 30));
      expect(wall.isUtc, isTrue);
      expect(
        clock.utcInstantOf(_dhaka, wall),
        DateTime.utc(2026, 3, 7, 20, 30),
      );
    });

    test('every Dhaka minute across the US DST days round-trips', () {
      for (final start in [
        DateTime.utc(2026, 3, 7, 12),
        DateTime.utc(2026, 10, 31, 12),
      ]) {
        for (var m = 0; m < 36 * 60; m += 10) {
          final utc = start.add(Duration(minutes: m));
          final wall = clock.instantAt(_dhaka, utc);
          final shifted = utc.add(const Duration(hours: 6));
          expect(wall, shifted, reason: '$utc');
          expect(clock.utcInstantOf(_dhaka, wall), utc, reason: '$utc');
        }
      }
    });

    test('wall arithmetic is plain field arithmetic', () {
      final wall = clock.instantAt(_dhaka, DateTime.utc(2026, 3, 7, 19, 45));
      expect(
        wall.add(const Duration(minutes: 45)),
        DateTime.utc(2026, 3, 8, 2, 30),
      );
      expect(
        DateTime.utc(2026, 3, 8, 3).difference(DateTime.utc(2026, 3, 8, 1)),
        const Duration(hours: 2),
      );
    });

    test("London's own DST: wall fields jump, instants stay real", () {
      // 29 Mar 2026: 01:00 GMT → 02:00 BST.
      expect(
        clock.instantAt(_london, DateTime.utc(2026, 3, 29, 0, 59)),
        DateTime.utc(2026, 3, 29, 0, 59),
      );
      expect(
        clock.instantAt(_london, DateTime.utc(2026, 3, 29, 1)),
        DateTime.utc(2026, 3, 29, 2),
      );
      final before = DateTime.utc(2026, 3, 28, 22);
      final fajr = DateTime.utc(2026, 3, 29, 5);
      expect(
        clock
            .utcInstantOf(_london, fajr)
            .difference(clock.utcInstantOf(_london, before)),
        const Duration(hours: 6),
      );
    });
  });
}
