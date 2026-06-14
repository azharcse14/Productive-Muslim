/// A full hadith collection in the online catalog (e.g. Sahih al-Bukhari).
/// Navigation metadata ships bundled; hadith text is fetched on demand.
final class HadithBook {
  const HadithBook({
    required this.id,
    required this.en,
    required this.bn,
    required this.author,
    required this.kind,
    required this.total,
    required this.editionAr,
    required this.editionEn,
    required this.editionBn,
    required this.sections,
  });

  /// Stable id, also the API collection key, e.g. "bukhari".
  final String id;
  final String en;
  final String bn;
  final String author;

  /// "sahih" — the whole book is rigorously authentic (Bukhari/Muslim);
  /// "graded" — authenticity varies per hadith, so a per-hadith grade shows.
  final String kind;

  /// Total hadith count (dataset numbering).
  final int total;

  /// API edition keys for Arabic / English / Bengali text.
  final String editionAr;
  final String editionEn;
  final String editionBn;

  final List<HadithSection> sections;

  bool get isSahih => kind == 'sahih';

  String titleFor(String languageCode) => switch (languageCode) {
        'bn' when bn.isNotEmpty => bn,
        _ => en,
      };

  /// Edition key for the reader's translation language.
  String translationEdition(String languageCode) =>
      languageCode == 'bn' ? editionBn : editionEn;
}

/// One chapter/section of a [HadithBook].
final class HadithSection {
  const HadithSection({
    required this.number,
    required this.name,
    required this.first,
    required this.last,
  });

  final int number;
  final String name;

  /// First/last hadith number in this section (null when unknown).
  final int? first;
  final int? last;

  int? get count =>
      (first != null && last != null) ? (last! - first! + 1) : null;
}

/// A single hadith fetched from the online dataset.
final class BookHadith {
  const BookHadith({
    required this.number,
    required this.arabic,
    required this.translation,
    required this.grade,
    required this.reference,
  });

  final int number;
  final String arabic;
  final String translation;

  /// Authenticity grade, e.g. "Sahih" / "Hasan" / "Da'if" — empty when none.
  final String grade;

  /// Display citation, e.g. "Sahih al-Bukhari 1".
  final String reference;
}
