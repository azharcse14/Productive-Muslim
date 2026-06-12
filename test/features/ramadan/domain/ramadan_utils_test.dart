import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/utils/hijri_date.dart';
import 'package:qalbee/features/ramadan/domain/usecases/ramadan_utils.dart';

void main() {
  group('RamadanUtils.isRamadan / rozaDay', () {
    test('true and 1..N inside Ramadan', () {
      expect(RamadanUtils.isRamadan(const HijriDate(1447, 9, 1)), isTrue);
      expect(RamadanUtils.rozaDay(const HijriDate(1447, 9, 1)), 1);
      expect(RamadanUtils.rozaDay(const HijriDate(1447, 9, 15)), 15);
      expect(RamadanUtils.rozaDay(const HijriDate(1447, 9, 30)), 30);
    });

    test('false and null outside Ramadan', () {
      for (final month in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]) {
        final d = HijriDate(1447, month, 10);
        expect(RamadanUtils.isRamadan(d), isFalse, reason: 'month $month');
        expect(RamadanUtils.rozaDay(d), isNull, reason: 'month $month');
      }
    });
  });

  group('RamadanUtils.ramadanLength', () {
    test('is 29 or 30 and matches the tabular calendar', () {
      for (var year = 1440; year <= 1460; year++) {
        final length = RamadanUtils.ramadanLength(year);
        expect(length, anyOf(29, 30));
        expect(length, HijriDate.daysInMonth(year, HijriDate.ramadanMonth));
      }
    });
  });

  group('RamadanUtils.firstDayOf', () {
    test('round-trips to 1 Ramadan of the same year', () {
      for (final year in [1446, 1447, 1448, 1460]) {
        final first = RamadanUtils.firstDayOf(year);
        expect(
          HijriDate.fromGregorian(first),
          HijriDate(year, HijriDate.ramadanMonth, 1),
        );
      }
    });

    test('1 Ramadan 1447 lands mid-February 2026 (tabular)', () {
      final first = RamadanUtils.firstDayOf(1447);
      expect(first.year, 2026);
      expect(first.month, DateTime.february);
      expect(first.day, inInclusiveRange(16, 20));
    });
  });

  group('RamadanUtils.gregorianDaysOf', () {
    test('length matches ramadanLength and starts at firstDayOf', () {
      for (final year in [1446, 1447, 1448]) {
        final days = RamadanUtils.gregorianDaysOf(year);
        expect(days.length, RamadanUtils.ramadanLength(year));
        expect(days.first, RamadanUtils.firstDayOf(year));
      }
    });

    test('days are contiguous civil dates', () {
      final days = RamadanUtils.gregorianDaysOf(1447);
      for (var i = 1; i < days.length; i++) {
        expect(
          days[i].difference(days[i - 1]).inDays,
          1,
          reason: 'gap between ${days[i - 1]} and ${days[i]}',
        );
      }
    });

    test('every day round-trips into Ramadan with the right roza number',
        () {
      final days = RamadanUtils.gregorianDaysOf(1447);
      for (var i = 0; i < days.length; i++) {
        final hijri = HijriDate.fromGregorian(days[i]);
        expect(RamadanUtils.rozaDay(hijri), i + 1);
      }
    });
  });

  group('RamadanUtils.nextRamadan', () {
    // All expectations are derived from the calendar itself (round-trip),
    // never hardcoded Gregorian dates.
    final first1447 = RamadanUtils.firstDayOf(1447);
    final first1448 = RamadanUtils.firstDayOf(1448);

    test('before Ramadan 1447 → (1447, positive day count)', () {
      final today = first1447.subtract(const Duration(days: 40));
      final (year, daysUntil) = RamadanUtils.nextRamadan(today);
      expect(year, 1447);
      expect(daysUntil, 40);
    });

    test('on 1 Ramadan 1447 → (1447, 0)', () {
      expect(RamadanUtils.nextRamadan(first1447), (1447, 0));
    });

    test('inside Ramadan 1447 → (1447, 0)', () {
      final inside = first1447.add(const Duration(days: 12));
      expect(RamadanUtils.nextRamadan(inside), (1447, 0));
    });

    test('on the last day of Ramadan 1447 → still (1447, 0)', () {
      final last = RamadanUtils.gregorianDaysOf(1447).last;
      expect(RamadanUtils.nextRamadan(last), (1447, 0));
    });

    test('after Ramadan 1447 (Eid day) → (1448, days to 1 Ramadan 1448)',
        () {
      final eid = RamadanUtils.gregorianDaysOf(1447)
          .last
          .add(const Duration(days: 1));
      final (year, daysUntil) = RamadanUtils.nextRamadan(eid);
      expect(year, 1448);
      expect(daysUntil, first1448.difference(eid).inDays);
      expect(daysUntil, greaterThan(300)); // ~a lunar year minus Ramadan.
    });

    test('time-of-day is ignored (civil-date difference)', () {
      final lateEvening = DateTime(
        first1447.year,
        first1447.month,
        first1447.day - 1,
        23,
        59,
      );
      expect(RamadanUtils.nextRamadan(lateEvening), (1447, 1));
    });
  });
}
