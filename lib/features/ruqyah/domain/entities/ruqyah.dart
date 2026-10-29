/// One ruqyah passage — a Qur'anic verse or an authentic prophetic
/// supplication recited for protection and healing (ruqyah ash-shar'iyyah).
final class RuqyahItem {
  const RuqyahItem({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
    required this.translationBn,
    required this.reference,
    required this.repeat,
    this.detailsEn = '',
    this.detailsBn = '',
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final String arabic;
  final String transliteration;
  final String translationEn;
  final String translationBn;

  /// Source citation (Qur'an reference or hadith collection).
  final String reference;

  /// Authentic recitation count (1/3/7/100) — drives the repeat chip.
  final int repeat;

  /// Optional explanation: context, how scholars applied it, practical use.
  final String detailsEn;
  final String detailsBn;

  String detailsFor(String languageCode) => switch (languageCode) {
    'bn' when detailsBn.isNotEmpty => detailsBn,
    _ => detailsEn,
  };

  String titleFor(String languageCode) => switch (languageCode) {
    'bn' when titleBn.isNotEmpty => titleBn,
    _ => titleEn,
  };

  String translationFor(String languageCode) => switch (languageCode) {
    'bn' when translationBn.isNotEmpty => translationBn,
    _ => translationEn,
  };
}

/// A themed group of ruqyah passages (protection, healing, evil eye…).
final class RuqyahCategory {
  const RuqyahCategory({
    required this.id,
    required this.icon,
    required this.items,
  });

  /// l10n key (ruqyahCategoryName select) and stable id.
  final String id;

  /// TrackerVisuals-compatible icon key.
  final String icon;
  final List<RuqyahItem> items;
}
