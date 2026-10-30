import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/locked_prayers.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

/// High-latitude summer: each day's isha starts at 00:30 the next day.
PrayerDay _day(DateTime d) {
  DateTime at(int plus, int h, [int m = 0]) =>
      DateTime(d.year, d.month, d.day + plus, h, m);
  return PrayerDay(
    fajr: at(0, 2, 30),
    sunrise: at(0, 4),
    dhuhr: at(0, 13),
    asr: at(0, 17),
    maghrib: at(0, 22),
    isha: at(1, 0, 30),
    fajrTomorrow: at(1, 2, 30),
    ishaYesterday: at(0, 0, 30),
  );
}

void main() {
  final now = DateTime(2026, 6, 15, 0, 10);
  Set<Prayer> locked(DateTime date, {bool known = true}) => lockedPrayersOn(
    date: date,
    now: now,
    dayOn: (d) => known ? _day(d) : null,
  );

  test("yesterday's isha starting after midnight stays locked", () {
    expect(locked(DateTime(2026, 6, 14)), {Prayer.isha});
  });

  test('today locks every prayer not yet begun', () {
    expect(locked(DateTime(2026, 6, 15)), {...Prayer.values});
  });

  test('older days and unknown prayer days lock nothing', () {
    expect(locked(DateTime(2026, 6, 13)), isEmpty);
    expect(locked(DateTime(2026, 6, 15), known: false), isEmpty);
  });
}
