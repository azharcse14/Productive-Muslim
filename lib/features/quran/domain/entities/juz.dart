import 'ayah.dart';

/// First ayah of each of the 30 juz (index 0 = juz 1), the standard Hafs
/// division as in Tanzil's quran-data. The bundled DB has no juz column.
const juzStarts = <QuranPosition>[
  QuranPosition(1, 1),
  QuranPosition(2, 142),
  QuranPosition(2, 253),
  QuranPosition(3, 93),
  QuranPosition(4, 24),
  QuranPosition(4, 148),
  QuranPosition(5, 82),
  QuranPosition(6, 111),
  QuranPosition(7, 88),
  QuranPosition(8, 41),
  QuranPosition(9, 93),
  QuranPosition(11, 6),
  QuranPosition(12, 53),
  QuranPosition(15, 1),
  QuranPosition(17, 1),
  QuranPosition(18, 75),
  QuranPosition(21, 1),
  QuranPosition(23, 1),
  QuranPosition(25, 21),
  QuranPosition(27, 56),
  QuranPosition(29, 46),
  QuranPosition(33, 31),
  QuranPosition(36, 28),
  QuranPosition(39, 32),
  QuranPosition(41, 47),
  QuranPosition(46, 1),
  QuranPosition(51, 31),
  QuranPosition(58, 1),
  QuranPosition(67, 1),
  QuranPosition(78, 1),
];

/// Surah ids juz [juz] (1-based) covers, in order — including a surah it
/// only starts or finishes partway through.
List<int> surahsInJuz(int juz) {
  final start = juzStarts[juz - 1].surah;
  var end = 114;
  if (juz < juzStarts.length) {
    final next = juzStarts[juz];
    end = next.ayah == 1 ? next.surah - 1 : next.surah;
  }
  return [for (var s = start; s <= end; s++) s];
}
