/// One of the 114 surahs (bundled DB metadata).
final class Surah {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.transliteration,
    required this.translationEn,
    required this.ayahCount,
    required this.revelation,
  });

  /// 1..114.
  final int id;
  final String nameArabic;
  final String transliteration;
  final String translationEn;
  final int ayahCount;

  /// 'meccan' | 'medinan'.
  final String revelation;

  @override
  bool operator ==(Object other) => other is Surah && other.id == id;

  @override
  int get hashCode => id;
}
