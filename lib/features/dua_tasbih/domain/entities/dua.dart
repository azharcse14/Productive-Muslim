/// Ids of duas removed as same-category duplicates, mapped to the entry that
/// was kept. Ids are persisted (favorites), so a stored old id must still
/// resolve.
const duaIdAliases = <String, String>{
  'fd_bismillah': 'bismillah_food',
  'hm_8_17_154': 'bismillah_tawakkaltu',
  'tv_safar': 'dua_safar',
  'hm_5_13_112': 'mk_entering_market',
};

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
  const DuaCategory({required this.id, required this.icon, required this.duas});

  /// l10n key (duaCategoryName select) and stable id.
  final String id;

  /// TrackerVisuals-compatible icon key.
  final String icon;
  final List<Dua> duas;
}

/// Which bundled name list: Allah's 99 names or the Prophet's ﷺ names.
/// `.name` is persisted (quiz best-score keys).
enum NameSet { allah, rasul }

/// One numbered name — of Allah (Asmaul Husna) or of the Prophet ﷺ.
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
