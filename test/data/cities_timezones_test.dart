import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:timezone/timezone.dart' as tz;

/// Guards the tz data variant: `latest`/`latest_10y` drop link zones (e.g.
/// Africa/Kinshasa) that bundled cities use, so only `latest_all` works.
void main() {
  test('every city timezone exists in the bundled tz database', () {
    TimezoneClock.initialize();
    final cities = jsonDecode(
      File('assets/data/cities.json').readAsStringSync(),
    ) as List<dynamic>;
    final missing = {
      for (final c in cities.cast<List<dynamic>>()) c[4] as String,
    }.where((id) => !tz.timeZoneDatabase.locations.containsKey(id)).toList();
    expect(missing, isEmpty);
  });
}
