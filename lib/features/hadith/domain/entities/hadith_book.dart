/// A full hadith collection in the online catalog (e.g. Sahih al-Bukhari).
/// Navigation metadata ships bundled; hadith text is fetched on demand.
final class HadithBook {
  const HadithBook({
    required this.id,
    required this.en,
    required this.bn,
    required this.author,
    required this.kind,
    this.authorBn = '',
    required this.total,
    required this.editionAr,
    required this.editionEn,
    required this.editionBn,
    required this.sections,
    this.bnAvailable = true,
    this.bnFolder = '',
    this.bnSections = const [],
  });

  /// Stable id, also the API collection key, e.g. "bukhari".
  final String id;
  final String en;
  final String bn;
  final String author;

  /// Bengali compiler name; falls back to [author] when empty.
  final String authorBn;

  /// "sahih" — the whole book is rigorously authentic (Bukhari/Muslim);
  /// "graded" — authenticity varies per hadith, so a per-hadith grade shows.
  final String kind;

  /// Total hadith count (dataset numbering).
  final int total;

  /// API edition keys for Arabic / English / Bengali text.
  final String editionAr;
  final String editionEn;
  final String editionBn;

  /// English chapter list (fawazahmed0 numbering).
  final List<HadithSection> sections;

  /// Whether any Bengali translation exists for this book at all. False only
  /// for books no source covers (e.g. 40 Hadith Qudsi) — drives the
  /// "English only" hint.
  final bool bnAvailable;

  /// hadithbangla repo folder (e.g. "Bukhari"); empty when that source has no
  /// Bengali edition of this book.
  final String bnFolder;

  /// Bengali chapter list (hadithbangla numbering + Bangla titles). Used only
  /// in the bn locale; its numbering is independent of [sections].
  final List<HadithSection> bnSections;

  bool get isSahih => kind == 'sahih';

  /// True when the reader's language should be served by the Bengali
  /// hadithbangla source rather than fawazahmed0.
  bool usesBanglaSource(String languageCode) =>
      languageCode == 'bn' && bnFolder.isNotEmpty && bnSections.isNotEmpty;

  /// The chapter list to show for [languageCode] — Bengali chapters (with
  /// Bangla titles) when available, else the English list.
  List<HadithSection> sectionsFor(String languageCode) =>
      usesBanglaSource(languageCode) ? bnSections : sections;

  String titleFor(String languageCode) => switch (languageCode) {
        'bn' when bn.isNotEmpty => bn,
        _ => en,
      };

  String authorFor(String languageCode) => switch (languageCode) {
        'bn' when authorBn.isNotEmpty => authorBn,
        _ => author,
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
    this.narrator = '',
    this.fallbackTranslation = false,
  });

  final int number;
  final String arabic;
  final String translation;

  /// Authenticity grade, e.g. "Sahih" / "Hasan" / "সহিহ হাদিস" — empty when none.
  final String grade;

  /// Display citation, e.g. "Sahih al-Bukhari 1".
  final String reference;

  /// Narrating companion (Bengali source only); empty otherwise.
  final String narrator;

  /// True when the reader asked for Bengali but only English was available for
  /// this hadith — drives the "showing English" note.
  final bool fallbackTranslation;
}
