/// One hadith from the bundled collection.
final class Hadith {
  const Hadith({
    required this.id,
    required this.arabic,
    required this.en,
    required this.bn,
    required this.narrator,
    required this.reference,
  });

  final String id;
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
