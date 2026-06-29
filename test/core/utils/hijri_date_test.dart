import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';

void main() {
  group('HijriDate (tabular, civil epoch)', () {
    test('epoch: 1 Muharram 1 AH = 19 July 622 (proleptic Gregorian)', () {
      expect(const HijriDate(1, 1, 1).toGregorian(), DateTime(622, 7, 19));
      expect(HijriDate.fromGregorian(DateTime(622, 7, 19)),
          const HijriDate(1, 1, 1));
    });

    test('round-trips across a decade of dates', () {
      var date = DateTime(2020);
      while (date.isBefore(DateTime(2031))) {
        final hijri = HijriDate.fromGregorian(date);
        expect(hijri.toGregorian(), date, reason: 'failed for $date');
        date = date.add(const Duration(days: 17));
      }
    });

    test('month lengths alternate 30/29; Dhul-Hijjah 30 only in leap years',
        () {
      expect(HijriDate.daysInMonth(1447, 1), 30);
      expect(HijriDate.daysInMonth(1447, 2), 29);
      expect(HijriDate.daysInMonth(1447, 9), 30); // Ramadan
      // 1447: (1447-1)%30+1 = 7 → leap.
      expect(HijriDate.isLeapYear(1447), isTrue);
      expect(HijriDate.daysInMonth(1447, 12), 30);
      expect(HijriDate.isLeapYear(1446), isFalse);
      expect(HijriDate.daysInMonth(1446, 12), 29);
    });

    test('11 leap years per 30-year cycle', () {
      final leaps = [
        for (var y = 1441; y <= 1470; y++)
          if (HijriDate.isLeapYear(y)) y,
      ];
      expect(leaps.length, 11);
    });

    test('consecutive days never skip or repeat', () {
      var prev = HijriDate.fromGregorian(DateTime(2026));
      for (var d = 2; d <= 365; d++) {
        final current =
            HijriDate.fromGregorian(DateTime(2026).add(Duration(days: d - 1)));
        final prevG = prev.toGregorian();
        final curG = current.toGregorian();
        expect(curG.difference(prevG).inDays, 1);
        prev = current;
      }
    });

    test('design-brief sample date lands within ±1 day of Umm al-Qura', () {
      // Design sample: 12 Jun 2026 ≈ 26 Dhul-Hijjah 1447 (UAQ).
      final hijri = HijriDate.fromGregorian(DateTime(2026, 6, 12));
      expect(hijri.year, 1447);
      expect(hijri.month, 12);
      expect(hijri.day, inInclusiveRange(25, 27));
    });

    test('Ramadan month constant', () {
      expect(HijriDate.ramadanMonth, 9);
    });
  });
}
