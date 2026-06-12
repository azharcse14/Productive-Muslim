import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/utils/hijri_date.dart';
import 'package:qalbee/core/utils/islamic_dates.dart';

void main() {
  group('IslamicDates.all', () {
    test('contains every IslamicDay exactly once, in calendar order', () {
      expect(
        IslamicDates.all.map((e) => e.day),
        containsAllInOrder(IslamicDay.values),
      );
      expect(IslamicDates.all.length, IslamicDay.values.length);
    });
  });

  group('IslamicDates.of', () {
    test('hits for every entry', () {
      for (final entry in IslamicDates.all) {
        final d = HijriDate(1447, entry.month, entry.hijriDay);
        expect(IslamicDates.of(d), entry.day, reason: '$entry');
      }
    });

    test('expected mapping for key dates', () {
      expect(IslamicDates.of(const HijriDate(1447, 1, 1)),
          IslamicDay.hijriNewYear);
      expect(IslamicDates.of(const HijriDate(1447, 1, 10)), IslamicDay.ashura);
      expect(IslamicDates.of(const HijriDate(1447, 3, 12)), IslamicDay.mawlid);
      expect(
          IslamicDates.of(const HijriDate(1447, 7, 27)), IslamicDay.israMiraj);
      expect(IslamicDates.of(const HijriDate(1447, 8, 15)),
          IslamicDay.nisfShaban);
      expect(IslamicDates.of(const HijriDate(1447, 9, 1)),
          IslamicDay.ramadanStart);
      expect(IslamicDates.of(const HijriDate(1447, 9, 27)),
          IslamicDay.laylatulQadr);
      expect(
          IslamicDates.of(const HijriDate(1447, 10, 1)), IslamicDay.eidAlFitr);
      expect(IslamicDates.of(const HijriDate(1447, 12, 9)), IslamicDay.arafah);
      expect(IslamicDates.of(const HijriDate(1447, 12, 10)),
          IslamicDay.eidAlAdha);
    });

    test('null on ordinary days', () {
      expect(IslamicDates.of(const HijriDate(1447, 1, 2)), isNull);
      expect(IslamicDates.of(const HijriDate(1447, 1, 11)), isNull);
      expect(IslamicDates.of(const HijriDate(1447, 2, 10)), isNull);
      expect(IslamicDates.of(const HijriDate(1447, 9, 26)), isNull);
      expect(IslamicDates.of(const HijriDate(1447, 10, 2)), isNull);
      expect(IslamicDates.of(const HijriDate(1447, 12, 11)), isNull);
    });
  });

  group('IslamicDates.inGregorianMonth', () {
    test('finds Eid al-Fitr 1447 in its tabular Gregorian month', () {
      // Derive the month from the calendar itself, never hardcoded.
      final eid = const HijriDate(1447, 10, 1).toGregorian();
      final events = IslamicDates.inGregorianMonth(eid.year, eid.month);
      expect(events, contains((IslamicDay.eidAlFitr, eid)));
    });

    test('a Gregorian month spanning two hijri months yields both events',
        () {
      // The month of 1 Ramadan 1447 also contains 15 Shaban 1447 (Shaban
      // runs into it), exercising the hijri month boundary.
      final ramadanStart = const HijriDate(1447, 9, 1).toGregorian();
      final nisf = const HijriDate(1447, 8, 15).toGregorian();
      expect(nisf.month, ramadanStart.month, reason: 'fixture assumption');
      final events = IslamicDates.inGregorianMonth(
        ramadanStart.year,
        ramadanStart.month,
      );
      expect(events, [
        (IslamicDay.nisfShaban, nisf),
        (IslamicDay.ramadanStart, ramadanStart),
      ]);
    });

    test('a Gregorian month spanning two hijri years finds the new year',
        () {
      final newYear = const HijriDate(1448, 1, 1).toGregorian();
      final events = IslamicDates.inGregorianMonth(
        newYear.year,
        newYear.month,
      );
      expect(events, contains((IslamicDay.hijriNewYear, newYear)));
      // Days before the 1st of Muharram in that month belong to 1447 —
      // walking the month must not miss or duplicate anything around the
      // year boundary.
      expect(
        HijriDate.fromGregorian(
          newYear.subtract(const Duration(days: 1)),
        ).year,
        1447,
      );
    });

    test('results are in chronological order', () {
      final eid = const HijriDate(1447, 10, 1).toGregorian();
      final events = IslamicDates.inGregorianMonth(eid.year, eid.month);
      expect(events.length, greaterThanOrEqualTo(2)); // Qadr 27/9 + Eid 1/10.
      for (var i = 1; i < events.length; i++) {
        expect(events[i].$2.isAfter(events[i - 1].$2), isTrue);
      }
    });

    test('a month with no events returns an empty list', () {
      // The month after Eid al-Fitr 1447 covers late Shawwal and early
      // Dhul-Qadah, neither of which carries an event.
      final eid = const HijriDate(1447, 10, 1).toGregorian();
      final events = IslamicDates.inGregorianMonth(eid.year, eid.month + 1);
      expect(events, isEmpty);
    });

    test('every event of hijri year 1447 is found in some Gregorian month',
        () {
      final found = <IslamicDay>{};
      for (final entry in IslamicDates.all) {
        final g = HijriDate(1447, entry.month, entry.hijriDay).toGregorian();
        for (final (day, date) in IslamicDates.inGregorianMonth(
          g.year,
          g.month,
        )) {
          if (day == entry.day && date == g) {
            found.add(day);
          }
        }
      }
      expect(found, IslamicDay.values.toSet());
    });
  });
}
