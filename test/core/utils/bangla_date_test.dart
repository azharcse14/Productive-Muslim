import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/bangla_date.dart';

void main() {
  group('BanglaDate (BD revised calendar)', () {
    test('Pohela Boishakh: 14 April 2026 → 1 Boishakh 1433', () {
      expect(
        BanglaDate.fromGregorian(DateTime(2026, 4, 14)),
        const BanglaDate(1433, 1, 1),
      );
    });

    test('design-brief sample: 12 Jun 2026 → 29 Joishtho 1433', () {
      expect(
        BanglaDate.fromGregorian(DateTime(2026, 6, 12)),
        const BanglaDate(1433, 2, 29),
      );
    });

    test('day before new year is 30 Choitro of the previous year', () {
      expect(
        BanglaDate.fromGregorian(DateTime(2026, 4, 13)),
        const BanglaDate(1432, 12, 30),
      );
    });

    test('Pohela Falgun is 14 February in the revised calendar', () {
      expect(
        BanglaDate.fromGregorian(DateTime(2026, 2, 14)),
        const BanglaDate(1432, 11, 1),
      );
    });

    test('Falgun has 30 days when its Gregorian year is leap', () {
      // Bengali year starting Apr 2027: Falgun falls in 2028 (leap).
      // Falgun 1 = 14 Feb 2028; Falgun 30 = 14 Mar 2028; Choitro 1 = 15 Mar.
      expect(
        BanglaDate.fromGregorian(DateTime(2028, 3, 14)),
        const BanglaDate(1434, 11, 30),
      );
      expect(
        BanglaDate.fromGregorian(DateTime(2028, 3, 15)),
        const BanglaDate(1434, 12, 1),
      );
    });

    test('Falgun has 29 days in a normal year', () {
      // Bengali year starting Apr 2025: Falgun falls in 2026 (not leap).
      expect(
        BanglaDate.fromGregorian(DateTime(2026, 3, 14)),
        const BanglaDate(1432, 11, 29),
      );
      expect(
        BanglaDate.fromGregorian(DateTime(2026, 3, 15)),
        const BanglaDate(1432, 12, 1),
      );
    });

    test('year boundary across 365 consecutive days stays contiguous', () {
      var prev = BanglaDate.fromGregorian(DateTime(2026));
      for (var d = 1; d < 365; d++) {
        final cur = BanglaDate.fromGregorian(DateTime(2026, 1, 1 + d));
        final sameMonth = cur.month == prev.month && cur.day == prev.day + 1;
        final newMonth = cur.day == 1 && cur.month != prev.month;
        expect(sameMonth || newMonth, isTrue,
            reason: 'discontinuity at day $d: $prev → $cur');
        prev = cur;
      }
    });
  });

  // DST-sensitive: only bites in a southern-hemisphere DST zone (e.g.
  // TZ=Australia/Sydney); holds in every zone.
  test('day count is exact across DST changes', () {
    for (var d = DateTime(2026, 4, 14);
        d.year < 2028;
        d = DateTime(d.year, d.month, d.day + 1)) {
      final b = BanglaDate.fromGregorian(d);
      final next = BanglaDate.fromGregorian(
        DateTime(d.year, d.month, d.day + 1),
      );
      expect(
        next.day == b.day + 1 || (next.day == 1 && next.month != b.month),
        isTrue,
        reason: '$d: $b → $next',
      );
    }
  });
}
