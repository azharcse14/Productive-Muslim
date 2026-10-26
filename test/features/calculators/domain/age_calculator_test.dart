// Explicit DateTime(year, 1, 1) literals read more clearly in date-math
// assertions than the bare DateTime(year) shorthand.
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/features/calculators/domain/usecases/age_calculator.dart';

void main() {
  group('AgeCalculator.calculate — Gregorian', () {
    test('exact whole years: 2000-01-01 → 2020-01-01 = 20y 0m 0d', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 1, 1),
        onDate: DateTime(2020, 1, 1),
      );
      expect(r.gregorian.years, 20);
      expect(r.gregorian.months, 0);
      expect(r.gregorian.days, 0);
    });

    test('birthDate == onDate → all zeros, totalDays 0', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(1990, 5, 15),
        onDate: DateTime(1990, 5, 15),
      );
      expect(r.gregorian.years, 0);
      expect(r.gregorian.months, 0);
      expect(r.gregorian.days, 0);
      expect(r.hijri.years, 0);
      expect(r.hijri.months, 0);
      expect(r.hijri.days, 0);
      expect(r.totalDays, 0);
    });

    test('onDate before birthDate → clamped to zeros', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2020, 1, 1),
        onDate: DateTime(2000, 1, 1),
      );
      expect(r.gregorian.years, 0);
      expect(r.gregorian.months, 0);
      expect(r.gregorian.days, 0);
      expect(r.hijri.years, 0);
      expect(r.totalDays, 0);
    });

    test('mid-month, no borrow: 2000-03-10 → 2020-07-25 = 20y 4m 15d', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 3, 10),
        onDate: DateTime(2020, 7, 25),
      );
      expect(r.gregorian.years, 20);
      expect(r.gregorian.months, 4);
      expect(r.gregorian.days, 15);
    });

    test('day borrow across February (28-day month): 2000-02-15 → 2000-03-01',
        () {
      // March's preceding month is Feb 2000 (leap) = 29 days.
      // days = 1 - 15 = -14 → + 29 = 15; months 3 - 2 - 1 = 0.
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 2, 15),
        onDate: DateTime(2000, 3, 1),
      );
      expect(r.gregorian.years, 0);
      expect(r.gregorian.months, 0);
      expect(r.gregorian.days, 15);
    });

    test('day borrow within year: 2000-01-20 → 2000-03-10 = 0y 1m 19d', () {
      // March's preceding month Feb 2000 is leap = 29 days.
      // days = 10 - 20 = -10 → + 29 (Feb 2000) = 19; months 3-1-1 = 1.
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 1, 20),
        onDate: DateTime(2000, 3, 10),
      );
      expect(r.gregorian.years, 0);
      expect(r.gregorian.months, 1);
      expect(r.gregorian.days, 19);
    });

    test('leap-day birthday Feb 29: 2000-02-29 → 2004-02-29 = 4y 0m 0d', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 2, 29),
        onDate: DateTime(2004, 2, 29),
      );
      expect(r.gregorian.years, 4);
      expect(r.gregorian.months, 0);
      expect(r.gregorian.days, 0);
    });

    test('month borrow then day borrow: 2000-12-15 → 2001-01-10', () {
      // months = 1 - 12 = -11; days = 10 - 15 = -5.
      // borrow day: preceding month of Jan is Dec 2000 = 31 → d = 26, m=-12.
      // borrow month: m = 0, y = 0. So 0y 0m 26d.
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 12, 15),
        onDate: DateTime(2001, 1, 10),
      );
      expect(r.gregorian.years, 0);
      expect(r.gregorian.months, 0);
      expect(r.gregorian.days, 26);
    });

    test('start day past end of borrowed month: 2001-01-31 → 2001-03-01',
        () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2001, 1, 31),
        onDate: DateTime(2001, 3, 1),
      );
      expect(r.gregorian.years, 0);
      expect(r.gregorian.months, 1);
      expect(r.gregorian.days, 1);
    });

    test('31st into a 30-day month: 2000-03-31 → 2000-05-01 = 0y 1m 1d', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 3, 31),
        onDate: DateTime(2000, 5, 1),
      );
      expect(r.gregorian.months, 1);
      expect(r.gregorian.days, 1);
    });

    test('totalDays across DST change (fails under local-time diff in '
        'DST zones, e.g. TZ=America/New_York)', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2020, 1, 1),
        onDate: DateTime(2020, 6, 30),
      );
      expect(r.totalDays, 181);
    });

    test('totalDays equals raw day difference', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2020, 1, 1),
        onDate: DateTime(2020, 1, 31),
      );
      expect(r.totalDays, 30);
    });

    test('totalDays across a leap year', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2000, 1, 1),
        onDate: DateTime(2001, 1, 1),
      );
      expect(r.totalDays, 366); // 2000 is a leap year
    });
  });

  group('AgeCalculator.calculate — Hijri', () {
    test('Hijri age matches a direct HijriDate borrow over the same span', () {
      final birth = DateTime(1990, 6, 14);
      final on = DateTime(2026, 6, 14);
      final r = AgeCalculator.calculate(birthDate: birth, onDate: on);

      // Derive the expected Hijri breakdown independently from the converter.
      final bh = HijriDate.fromGregorian(birth);
      final oh = HijriDate.fromGregorian(on);
      var years = oh.year - bh.year;
      var months = oh.month - bh.month;
      var days = oh.day - bh.day;
      if (days < 0) {
        var pm = oh.month - 1;
        var py = oh.year;
        if (pm == 0) {
          pm = 12;
          py -= 1;
        }
        days += HijriDate.daysInMonth(py, pm);
        months -= 1;
      }
      if (months < 0) {
        months += 12;
        years -= 1;
      }

      expect(r.hijri.years, years);
      expect(r.hijri.months, months);
      expect(r.hijri.days, days);
    });

    test('Hijri year count runs ahead of the Gregorian one for long spans',
        () {
      // ~36 Gregorian years ≈ ~37 Hijri years (Hijri year ~11 days shorter).
      final r = AgeCalculator.calculate(
        birthDate: DateTime(1980, 1, 1),
        onDate: DateTime(2016, 1, 1),
      );
      expect(r.gregorian.years, 36);
      expect(r.hijri.years, greaterThan(r.gregorian.years));
    });

    test('all Hijri fields are non-negative', () {
      final r = AgeCalculator.calculate(
        birthDate: DateTime(2001, 11, 27),
        onDate: DateTime(2024, 2, 3),
      );
      expect(r.hijri.years, greaterThanOrEqualTo(0));
      expect(r.hijri.months, inInclusiveRange(0, 11));
      expect(r.hijri.days, greaterThanOrEqualTo(0));
    });
  });
}
