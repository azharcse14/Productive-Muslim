import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/achievements/domain/achievements.dart';

AchievementProgress _find(List<AchievementProgress> list, String id) =>
    list.firstWhere((p) => p.achievement.id == id);

void main() {
  group('AchievementEvaluator thresholds', () {
    test('streak badge unlocks exactly at its threshold', () {
      final below = AchievementEvaluator.evaluate(
        const AchievementStats(bestStreak: 2),
      );
      final at = AchievementEvaluator.evaluate(
        const AchievementStats(bestStreak: 3),
      );
      expect(_find(below, 'streak_3').unlocked, isFalse);
      expect(_find(at, 'streak_3').unlocked, isTrue);
    });

    test('dhikr ladder unlocks 100/1000/10000 at boundaries', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(totalDhikr: 1000),
      );
      expect(_find(s, 'dhikr_100').unlocked, isTrue);
      expect(_find(s, 'dhikr_1000').unlocked, isTrue);
      expect(_find(s, 'dhikr_10000').unlocked, isFalse);
    });

    test('quran_start uses the started-reading flag', () {
      final none = AchievementEvaluator.evaluate(const AchievementStats());
      final started = AchievementEvaluator.evaluate(
        const AchievementStats(hasStartedReading: true),
      );
      expect(_find(none, 'quran_start').unlocked, isFalse);
      expect(_find(started, 'quran_start').unlocked, isTrue);
    });

    test('fasting ladder counts roza days', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(fastingDaysDone: 10),
      );
      expect(_find(s, 'fast_1').unlocked, isTrue);
      expect(_find(s, 'fast_10').unlocked, isTrue);
      expect(_find(s, 'fast_30').unlocked, isFalse);
    });
  });

  group('progress fractions', () {
    test('first-tier badge measures from zero', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(),
      );
      expect(_find(s, 'streak_3').fraction, 0.0);
    });

    test('mid-progress on first tier is fractional', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(totalDhikr: 50),
      );
      expect(_find(s, 'dhikr_100').fraction, closeTo(0.5, 1e-9));
    });

    test('higher-tier progress is measured from the previous threshold', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(totalDhikr: 550),
      );
      expect(_find(s, 'dhikr_100').unlocked, isTrue);
      expect(_find(s, 'dhikr_100').fraction, 1.0);
      expect(_find(s, 'dhikr_1000').unlocked, isFalse);
      expect(_find(s, 'dhikr_1000').fraction, closeTo(0.5, 1e-9));
    });

    test('unlocked badge always reports fraction 1.0', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(salahDaysDone: 500),
      );
      expect(_find(s, 'salah_200').unlocked, isTrue);
      expect(_find(s, 'salah_200').fraction, 1.0);
    });

    test('fraction clamps to 0..1 below the floor', () {
      final s = AchievementEvaluator.evaluate(
        const AchievementStats(bestStreak: 5),
      );
      expect(_find(s, 'streak_30').fraction, 0.0);
    });
  });

  group('tier transitions & counts', () {
    test('crossing a threshold flips exactly one ladder badge', () {
      final before = AchievementEvaluator.unlockedIds(
        const AchievementStats(salahDaysDone: 49),
      );
      final after = AchievementEvaluator.unlockedIds(
        const AchievementStats(salahDaysDone: 50),
      );
      expect(after.difference(before), {'salah_50'});
    });

    test('unlockedCount aggregates across categories', () {
      const s = AchievementStats(
        bestStreak: 7,
        salahDaysDone: 10,
        totalDhikr: 100,
        hasStartedReading: true,
      );
      // streak_3, streak_7, salah_10, dhikr_100, quran_start = 5.
      expect(AchievementEvaluator.unlockedCount(s), 5);
    });

    test('empty stats unlock nothing', () {
      expect(
        AchievementEvaluator.unlockedCount(const AchievementStats()),
        0,
      );
    });

    test('every catalog id is unique', () {
      final ids = AchievementCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
