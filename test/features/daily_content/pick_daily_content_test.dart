import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/daily_content/domain/usecases/pick_daily_content.dart';

void main() {
  group('pickDailyContent — determinism', () {
    test('same calendar day → same pick (ignores time of day)', () {
      final morning = DateTime(2026, 6, 14, 6, 30);
      final night = DateTime(2026, 6, 14, 23, 59, 59);
      final a = pickDailyContent(
        date: morning,
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      final b = pickDailyContent(
        date: night,
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      expect(a, b);
    });

    test('a different day generally produces a different pick', () {
      final d1 = pickDailyContent(
        date: DateTime(2026, 6, 14),
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      final d2 = pickDailyContent(
        date: DateTime(2026, 6, 15),
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      expect(d1 == d2, isFalse);
    });

    test('indices advance by exactly one per day (modular)', () {
      final d1 = pickDailyContent(
        date: DateTime(2026),
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      final d2 = pickDailyContent(
        date: DateTime(2026, 1, 2),
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      expect(d2.ayahIndex, (d1.ayahIndex! + 1) % 11);
      expect(d2.hadithIndex, (d1.hadithIndex! + 1) % 40);
      expect(d2.duaIndex, (d1.duaIndex! + 1) % 51);
    });

    test('rotation does not reset across the year boundary', () {
      final dec31 = pickDailyContent(
        date: DateTime(2025, 12, 31),
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      final jan1 = pickDailyContent(
        date: DateTime(2026),
        ayahPoolSize: 11,
        hadithPoolSize: 40,
        duaPoolSize: 51,
      );
      expect(jan1.hadithIndex, (dec31.hadithIndex! + 1) % 40);
    });
  });

  group('pickDailyContent — pools & boundaries', () {
    test('index always within pool bounds', () {
      for (var day = 1; day <= 400; day++) {
        final s = pickDailyContent(
          date: DateTime(2026).add(Duration(days: day)),
          ayahPoolSize: 11,
          hadithPoolSize: 40,
          duaPoolSize: 51,
        );
        expect(s.ayahIndex! >= 0 && s.ayahIndex! < 11, isTrue);
        expect(s.hadithIndex! >= 0 && s.hadithIndex! < 40, isTrue);
        expect(s.duaIndex! >= 0 && s.duaIndex! < 51, isTrue);
      }
    });

    test('empty pool yields a null index', () {
      final s = pickDailyContent(
        date: DateTime(2026, 6, 14),
        ayahPoolSize: 0,
        hadithPoolSize: 0,
        duaPoolSize: 0,
      );
      expect(s.ayahIndex, isNull);
      expect(s.hadithIndex, isNull);
      expect(s.duaIndex, isNull);
      expect(s.indexFor(DailyContentKind.hadith), isNull);
    });

    test('pool size 1 always picks index 0', () {
      final s = pickDailyContent(
        date: DateTime(2026, 6, 14),
        ayahPoolSize: 1,
        hadithPoolSize: 1,
        duaPoolSize: 1,
      );
      expect(s.ayahIndex, 0);
      expect(s.hadithIndex, 0);
      expect(s.duaIndex, 0);
    });

    test('indexFor maps each kind to its index', () {
      const s = DailyContentSelection(
        ayahIndex: 1,
        hadithIndex: 2,
        duaIndex: 3,
      );
      expect(s.indexFor(DailyContentKind.ayah), 1);
      expect(s.indexFor(DailyContentKind.hadith), 2);
      expect(s.indexFor(DailyContentKind.dua), 3);
    });
  });
}
