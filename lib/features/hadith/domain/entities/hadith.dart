/// One hadith from the bundled collection.
final class Hadith {
  const Hadith({
    required this.id,
    required this.topic,
    required this.grade,
    required this.arabic,
    required this.en,
    required this.bn,
    required this.narrator,
    required this.reference,
  });

  final String id;

  /// Topic bucket id (l10n key for [hadithTopicName]), e.g. "character".
  final String topic;

  /// Authenticity grade, e.g. "Sahih" or "Hasan".
  final String grade;

  final String arabic;
  final String en;
  final String bn;

  /// Narrating companion, e.g. "Abu Hurairah (RA)".
  final String narrator;

  /// Source citation, e.g. "Sahih Bukhari 1".
  final String reference;

  String translationFor(String languageCode) => switch (languageCode) {
        'bn' when bn.isNotEmpty => bn,
        _ => en,
      };
}

/// A topic with its hadith — grouping derived from [Hadith.topic].
final class HadithTopic {
  const HadithTopic({required this.id, required this.items});

  /// Stable id and l10n key (hadithTopicName select).
  final String id;
  final List<Hadith> items;
}
