import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/quran/domain/entities/juz.dart';

/// Ayah counts of surahs 1..114 (as in the bundled quran.db).
const _ayahCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, //
  111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
  54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49,
  62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28,
  28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
];

void main() {
  test('the ayah count table is the 114-surah, 6236-ayah Quran', () {
    expect(_ayahCounts, hasLength(114));
    expect(_ayahCounts.reduce((a, b) => a + b), 6236);
  });

  test('30 juz starts, valid and strictly ascending from 1:1', () {
    expect(juzStarts, hasLength(30));
    expect(juzStarts.first.surah, 1);
    expect(juzStarts.first.ayah, 1);
    var previous = (0, 0);
    for (final start in juzStarts) {
      expect(start.surah, inInclusiveRange(1, 114));
      expect(start.ayah, inInclusiveRange(1, _ayahCounts[start.surah - 1]));
      final current = (start.surah, start.ayah);
      expect(
        current.$1 > previous.$1 ||
            (current.$1 == previous.$1 && current.$2 > previous.$2),
        isTrue,
        reason: '$current after $previous',
      );
      previous = current;
    }
  });
}
