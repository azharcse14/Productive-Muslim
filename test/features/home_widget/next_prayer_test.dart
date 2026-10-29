import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/home_widget/domain/next_prayer.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

PrayerDay _day(DateTime d) => PrayerDay(
  fajr: DateTime(d.year, d.month, d.day, 4, 30),
  sunrise: DateTime(d.year, d.month, d.day, 5, 50),
  dhuhr: DateTime(d.year, d.month, d.day, 12, 10),
  asr: DateTime(d.year, d.month, d.day, 15, 40),
  maghrib: DateTime(d.year, d.month, d.day, 18, 25),
  isha: DateTime(d.year, d.month, d.day, 19, 45),
  fajrTomorrow: DateTime(d.year, d.month, d.day + 1, 4, 31),
  ishaYesterday: DateTime(d.year, d.month, d.day - 1, 19, 44),
);

void main() {
  final base = DateTime(2026, 6, 14);
  final day = _day(base);

  test('before fajr → next is today fajr', () {
    final next = resolveNextPrayer(day, DateTime(2026, 6, 14, 3));
    expect(next.prayer, Prayer.fajr);
    expect(next.at, day.fajr);
    expect(next.tomorrow, isFalse);
  });

  test('between dhuhr and asr → next is asr', () {
    final next = resolveNextPrayer(day, DateTime(2026, 6, 14, 13));
    expect(next.prayer, Prayer.asr);
    expect(next.at, day.asr);
  });

  test(
    'exactly at a waqt start picks the following prayer (strictly after)',
    () {
      final next = resolveNextPrayer(day, day.dhuhr);
      expect(next.prayer, Prayer.asr);
    },
  );

  test('after isha rolls over to tomorrow fajr', () {
    final next = resolveNextPrayer(day, DateTime(2026, 6, 14, 21));
    expect(next.prayer, Prayer.fajr);
    expect(next.at, day.fajrTomorrow);
    expect(next.tomorrow, isTrue);
  });

  test('before an after-midnight isha (high latitude) → next is that isha', () {
    final late = PrayerDay(
      fajr: DateTime(2026, 6, 14, 2, 30),
      sunrise: day.sunrise,
      dhuhr: day.dhuhr,
      asr: day.asr,
      maghrib: day.maghrib,
      isha: day.isha,
      fajrTomorrow: day.fajrTomorrow,
      ishaYesterday: DateTime(2026, 6, 14, 0, 40),
    );
    final next = resolveNextPrayer(late, DateTime(2026, 6, 14, 0, 10));
    expect(next.prayer, Prayer.isha);
    expect(next.at, late.ishaYesterday);
    expect(next.tomorrow, isFalse);
    expect(
      resolveNextPrayer(late, DateTime(2026, 6, 14, 1)).prayer,
      Prayer.fajr,
    );
  });
}
