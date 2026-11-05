/// One of the 25 prophets named in the Quran (bundled `prophets.json`), or a
/// person in the full lineage (`prophet_lineage.json`), who has names, an
/// order and a parent only.
final class Prophet {
  const Prophet({
    required this.id,
    required this.order,
    required this.nameAr,
    required this.nameEn,
    required this.nameBn,
    this.titleEn = '',
    this.titleBn = '',
    this.parent,
    this.parentDistant = false,
    this.summaryEn = const [],
    this.summaryBn = const [],
    this.quranMentions = const [],
    this.hadithRefs = const [],
    this.storyIds = const [],
  });

  final String id;

  /// Chronological position, 1 (Adam) to 25 (Muhammad ﷺ); in the full
  /// lineage, the display position.
  final int order;
  final String nameAr;
  final String nameEn;
  final String nameBn;

  /// Honorific, e.g. "Khalilullah"; empty when none.
  final String titleEn;
  final String titleBn;

  /// Id of the father/ancestor prophet; null when the link is unknown or
  /// disputed.
  final String? parent;

  /// Descent through many generations (drawn dashed).
  final bool parentDistant;
  final List<String> summaryEn;
  final List<String> summaryBn;

  /// `surah:ayah` or `surah:ayah-ayah`.
  final List<String> quranMentions;
  final List<String> hadithRefs;

  /// Ids of Quran stories about this prophet.
  final List<String> storyIds;

  String nameFor(String languageCode) =>
      languageCode == 'bn' && nameBn.isNotEmpty ? nameBn : nameEn;

  String titleFor(String languageCode) =>
      languageCode == 'bn' && titleBn.isNotEmpty ? titleBn : titleEn;

  List<String> summaryFor(String languageCode) =>
      languageCode == 'bn' && summaryBn.isNotEmpty ? summaryBn : summaryEn;
}
