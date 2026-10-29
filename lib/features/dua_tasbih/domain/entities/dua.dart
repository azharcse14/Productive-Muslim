/// One supplication from the bundled collection.
final class Dua {
  const Dua({
    required this.id,
    required this.arabic,
    required this.transliteration,
    this.transliterationBn = '',
    required this.translationEn,
    required this.translationBn,
    required this.reference,
    required this.repeat,
  });

  final String id;
  final String arabic;

  /// Latin transliteration (always present).
  final String transliteration;

  /// Bengali-script transliteration — empty for entries that lack one.
  final String transliterationBn;
  final String translationEn;
  final String translationBn;

  /// Source citation (surfaced in the detail view).
  final String reference;

  /// Authentic repetition count (1/3/4/7/10/33/34/100) — drives the repeat ring.
  final int repeat;

  String transliterationFor(String languageCode) => switch (languageCode) {
        'bn' when transliterationBn.isNotEmpty => transliterationBn,
        _ => transliteration,
      };

  String translationFor(String languageCode) => switch (languageCode) {
        'bn' when translationBn.isNotEmpty => translationBn,
        _ => translationEn,
      };
}

final class DuaCategory {
  const DuaCategory({
    required this.id,
    required this.icon,
    required this.duas,
  });

  /// l10n key (duaCategoryName select) and stable id.
  final String id;

  /// TrackerVisuals-compatible icon key.
  final String icon;
  final List<Dua> duas;
}

/// One of the 99 names of Allah.
final class AsmaName {
  const AsmaName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaningEn,
    required this.meaningBn,
  });

  final int number;
  final String arabic;
  final String transliteration;
  final String meaningEn;
  final String meaningBn;

  String meaningFor(String languageCode) => switch (languageCode) {
        'bn' when meaningBn.isNotEmpty => meaningBn,
        _ => meaningEn,
      };
}
