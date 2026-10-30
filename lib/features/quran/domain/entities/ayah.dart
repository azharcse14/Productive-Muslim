/// One ayah with bundled translations.
final class Ayah {
  const Ayah({
    required this.id,
    required this.surah,
    required this.number,
    required this.arabic,
    required this.translationEn,
    required this.translationBn,
  });

  /// Global index 1..6236 (bookmark key).
  final int id;
  final int surah;

  /// Ayah number within the surah.
  final int number;
  final String arabic;
  final String translationEn;
  final String translationBn;

  /// Bundled translation for [languageCode], falling back to English.
  String translationFor(String languageCode) => switch (languageCode) {
    'bn' when translationBn.isNotEmpty => translationBn,
    _ => translationEn,
  };

  @override
  bool operator ==(Object other) => other is Ayah && other.id == id;

  @override
  int get hashCode => id;
}

/// Reading position (resume card + deep links `/quran/:surah/:ayah`).
final class QuranPosition {
  const QuranPosition(this.surah, this.ayah);

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) =>
      other is QuranPosition && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}
