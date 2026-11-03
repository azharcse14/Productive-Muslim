import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/core/utils/islamic_dates.dart';
import 'package:productive_muslim/features/fasting/domain/usecases/recommended_fasts.dart';
import 'package:productive_muslim/features/ramadan/domain/usecases/ramadan_utils.dart';

/// "Eid announced — Ramadan ended after 29 days" via
/// [HijriDate.shortRamadanYears], and every domain consumer following it.
void main() {
  // Tabular dates, computed before any override is set.
  final r29 = const HijriDate(1447, 9, 29).toGregorian();
  final r30 = const HijriDate(1447, 9, 30).toGregorian();
  final shawwal29 = const HijriDate(1447, 10, 29).toGregorian();
  final dhulQadah1 = const HijriDate(1447, 11, 1).toGregorian();

  DateTime next(DateTime d, [int n = 1]) =>
      DateTime(d.year, d.month, d.day + n);

  void shortYears(Set<int> years) => HijriDate.shortRamadanYears = () => years;

  tearDown(() => shortYears(const {}));

  test('without the override Ramadan has 30 days and the 30th is a fast', () {
    expect(HijriDate.fromGregorian(r30), const HijriDate(1447, 9, 30));
    expect(RamadanUtils.ramadanLength(1447), 30);
    expect(RecommendedFasts.isForbidden(HijriDate.fromGregorian(r30)), false);
    expect(IslamicDates.of(HijriDate.fromGregorian(r30)), isNull);
  });

  group('with Ramadan 1447 ended after 29 days', () {
    setUp(() => shortYears({1447}));

    test('the 30th day is 1 Shawwal and Shawwal absorbs the day', () {
      expect(HijriDate.fromGregorian(r29), const HijriDate(1447, 9, 29));
      expect(HijriDate.fromGregorian(r30), const HijriDate(1447, 10, 1));
      expect(HijriDate.fromGregorian(next(r30)), const HijriDate(1447, 10, 2));
      expect(HijriDate.fromGregorian(shawwal29), const HijriDate(1447, 10, 30));
      // Dhul-Qadah onwards (and Eid al-Adha) is unchanged.
      expect(HijriDate.fromGregorian(dhulQadah1), const HijriDate(1447, 11, 1));
      expect(HijriDate.daysInMonth(1447, 9), 29);
      expect(HijriDate.daysInMonth(1447, 10), 30);
    });

    test('round-trips every day from Shaban to Dhul-Qadah', () {
      var d = const HijriDate(1447, 8, 1).toGregorian();
      for (var i = 0; i < 100; i++, d = next(d)) {
        expect(HijriDate.fromGregorian(d).toGregorian(), d, reason: '$d');
      }
      expect(const HijriDate(1447, 10, 1).toGregorian(), r30);
    });

    test('Ramadan utilities give a 29-day month', () {
      expect(RamadanUtils.ramadanLength(1447), 29);
      expect(RamadanUtils.gregorianDaysOf(1447), hasLength(29));
      expect(RamadanUtils.gregorianDaysOf(1447).last, r29);
      expect(RamadanUtils.rozaDay(HijriDate.fromGregorian(r30)), isNull);
      expect(RamadanUtils.isRamadan(HijriDate.fromGregorian(r30)), false);
      // Eid day: the next Ramadan is next year's.
      expect(RamadanUtils.nextRamadan(r30).$1, 1448);
    });

    test('fasting is forbidden on the 30th day (now Eid)', () {
      expect(RecommendedFasts.isForbidden(HijriDate.fromGregorian(r30)), true);
      expect(RecommendedFasts.on(r30), isEmpty);
    });

    test('the calendar marks Eid al-Fitr on the 30th day, once', () {
      expect(
        IslamicDates.of(HijriDate.fromGregorian(r30)),
        IslamicDay.eidAlFitr,
      );
      expect(IslamicDates.of(HijriDate.fromGregorian(next(r30))), isNull);
    });

    test('other years keep 30-day Ramadans (year boundary)', () {
      final r30Next = const HijriDate(1448, 9, 30).toGregorian();
      expect(HijriDate.fromGregorian(r30Next), const HijriDate(1448, 9, 30));
      expect(RamadanUtils.ramadanLength(1446), 30);
      expect(RamadanUtils.ramadanLength(1448), 30);
      // 1 Muharram 1448 is untouched.
      final muharram = const HijriDate(1448, 1, 1).toGregorian();
      expect(HijriDate.fromGregorian(muharram), const HijriDate(1448, 1, 1));
    });

    test('composes with the moon-sighting offset (applied first)', () {
      shortYears(const {});
      final r30Late = const HijriDate(1447, 9, 30).toGregorian(offsetDays: -1);
      expect(r30Late, next(r30));
      shortYears({1447});
      expect(
        HijriDate.fromGregorian(r30Late, offsetDays: -1),
        const HijriDate(1447, 10, 1),
      );
      expect(
        HijriDate.fromGregorian(r30, offsetDays: -1),
        const HijriDate(1447, 9, 29),
      );
    });
  });

  test('offersEidAnnouncement: 29/30 Ramadan, and Eid only to undo', () {
    bool offers(HijriDate d, {bool ended = false}) =>
        RamadanUtils.offersEidAnnouncement(d, ended: ended);
    expect(offers(const HijriDate(1447, 9, 28)), false);
    expect(offers(const HijriDate(1447, 9, 29)), true);
    expect(offers(const HijriDate(1447, 9, 30)), true);
    expect(offers(const HijriDate(1447, 9, 29), ended: true), true);
    expect(offers(const HijriDate(1447, 10, 1)), false);
    expect(offers(const HijriDate(1447, 10, 1), ended: true), true);
    expect(offers(const HijriDate(1447, 10, 2), ended: true), false);
  });
}
