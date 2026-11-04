/// Which collection a story comes from. Routed and persisted by `.name`.
enum StoryKind { quran, hadith }

/// One bundled story: a bilingual retelling with its Quran/hadith refs.
final class Story {
  const Story({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
    required this.refs,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final List<String> bodyEn;
  final List<String> bodyBn;

  /// `Quran 12:4-101` or `Bukhari 3450` style references.
  final List<String> refs;

  String titleFor(String languageCode) => switch (languageCode) {
    'bn' when titleBn.isNotEmpty => titleBn,
    _ => titleEn,
  };

  List<String> bodyFor(String languageCode) => switch (languageCode) {
    'bn' when bodyBn.isNotEmpty => bodyBn,
    _ => bodyEn,
  };
}
