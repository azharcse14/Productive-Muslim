import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/features/fasting/domain/entities/recommended_fast.dart';
import 'package:productive_muslim/features/fasting/domain/usecases/recommended_fasts.dart';

void main() {
  group('RecommendedFasts.on — weekly sunnah', () {
    test('Monday is recommended (2026-06-15 is a Monday)', () {
      final fasts = RecommendedFasts.on(DateTime(2026, 6, 15));
      expect(fasts.map((f) => f.kind), contains(FastingKind.mondayThursday));
    });

    test('Thursday is recommended (2026-06-18 is a Thursday)', () {
      final fasts = RecommendedFasts.on(DateTime(2026, 6, 18));
      expect(fasts.map((f) => f.kind), contains(FastingKind.mondayThursday));
    });

    test('an ordinary Wednesday is not recommended (2026-06-17)', () {
      expect(RecommendedFasts.on(DateTime(2026, 6, 17)), isEmpty);
    });

    test('time-of-day is ignored', () {
      final fasts = RecommendedFasts.on(DateTime(2026, 6, 15, 23, 59));
      expect(fasts.map((f) => f.kind), contains(FastingKind.mondayThursday));
    });
  });

  group('RecommendedFasts.on — fixed hijri observances (tabular calendar)', () {
    test('Ashura — 10 Muharram 1447 → 2025-07-06', () {
      final fasts = RecommendedFasts.on(DateTime(2025, 7, 6));
      expect(fasts.map((f) => f.kind), contains(FastingKind.ashura));
    });

    test('Tasua — 9 Muharram 1447 → 2025-07-05', () {
      final fasts = RecommendedFasts.on(DateTime(2025, 7, 5));
      expect(fasts.map((f) => f.kind), contains(FastingKind.ashura));
    });

    test('Arafah — 9 Dhul-Hijjah 1447 → 2026-05-26', () {
      final fasts = RecommendedFasts.on(DateTime(2026, 5, 26));
      expect(fasts.map((f) => f.kind), contains(FastingKind.arafah));
    });

    test('white day — 13 Muharram 1447 → 2025-07-09', () {
      final fasts = RecommendedFasts.on(DateTime(2025, 7, 9));
      expect(fasts.map((f) => f.kind), contains(FastingKind.whiteDays));
    });

    test('six-of-Shawwal — 2 Shawwal 1447 → 2026-03-21', () {
      final fasts = RecommendedFasts.on(DateTime(2026, 3, 21));
      expect(fasts.map((f) => f.kind), contains(FastingKind.shawwal));
    });
  });

  group('RecommendedFasts.on — forbidden days are NEVER recommended', () {
    test('Eid al-Fitr — 1 Shawwal 1447 → 2026-03-20', () {
      expect(RecommendedFasts.on(DateTime(2026, 3, 20)), isEmpty);
    });

    test('Eid al-Adha — 10 Dhul-Hijjah 1447 → 2026-05-27', () {
      expect(RecommendedFasts.on(DateTime(2026, 5, 27)), isEmpty);
    });

    test('day of Tashreeq — 11 Dhul-Hijjah 1447 → 2026-05-28', () {
      // Even though 14 Dhul-Hijjah would be a "white day", the Tashreeq
      // window (11–13) is excluded; this 11th carries no recommendation.
      expect(RecommendedFasts.on(DateTime(2026, 5, 28)), isEmpty);
    });
  });

  group('RecommendedFasts.upcoming', () {
    test('returns the requested count of recommended days in order', () {
      final list = RecommendedFasts.upcoming(DateTime(2026, 6, 14), count: 5);
      expect(list, hasLength(5));
      for (var i = 1; i < list.length; i++) {
        expect(
          list[i].fast.date.isAfter(list[i - 1].fast.date),
          isTrue,
          reason: 'dates must be strictly increasing',
        );
      }
      // Every returned day must itself be recommended.
      for (final item in list) {
        expect(RecommendedFasts.on(item.fast.date), isNotEmpty);
      }
    });

    test('from a Monday, that Monday is the first upcoming day', () {
      final list = RecommendedFasts.upcoming(DateTime(2026, 6, 15), count: 1);
      expect(list.first.fast.date, DateTime(2026, 6, 15));
    });
  });

  group('RecommendedFasts with a moon-sighting offset', () {
    // Tabular: Eid al-Fitr 1447 = 2026-03-20, Eid al-Adha = 2026-05-27,
    // Tashreeq = 28–30 May.
    test('offset −1: adjusted Eid al-Fitr (2026-03-21) is not recommended',
        () {
      // At offset 0 it is 2 Shawwal (six-of-Shawwal).
      expect(RecommendedFasts.isRecommended(DateTime(2026, 3, 21)), isTrue);
      expect(
        RecommendedFasts.on(DateTime(2026, 3, 21), offsetDays: -1),
        isEmpty,
      );
    });

    test('offset +1: adjusted Eid al-Fitr (2026-03-19, a Thursday) is not '
        'recommended', () {
      expect(DateTime(2026, 3, 19).weekday, DateTime.thursday);
      expect(RecommendedFasts.isRecommended(DateTime(2026, 3, 19)), isTrue);
      expect(
        RecommendedFasts.on(DateTime(2026, 3, 19), offsetDays: 1),
        isEmpty,
      );
    });

    test('offset ±1: no adjusted Eid/Tashreeq day is ever recommended', () {
      for (final offset in [-1, 1]) {
        final start = DateTime(2026);
        for (var i = 0; i < 400; i++) {
          final day = DateTime(start.year, start.month, start.day + i);
          final h = HijriDate.fromGregorian(day, offsetDays: offset);
          if (RecommendedFasts.isForbidden(h)) {
            expect(
              RecommendedFasts.on(day, offsetDays: offset),
              isEmpty,
              reason: '$day is forbidden at offset $offset',
            );
          }
        }
        final upcoming = RecommendedFasts.upcoming(
          DateTime(2026, 3),
          count: 120,
          offsetDays: offset,
        );
        expect(
          upcoming.any((u) => RecommendedFasts.isForbidden(u.hijri)),
          isFalse,
        );
        final eidAdha =
            const HijriDate(1447, 12, 10).toGregorian(offsetDays: offset);
        expect(upcoming.any((u) => u.fast.date == eidAdha), isFalse);
      }
    });
  });
}
