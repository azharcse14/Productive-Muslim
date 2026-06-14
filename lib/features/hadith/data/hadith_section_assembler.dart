import '../domain/entities/hadith_book.dart';

/// Pure assembly of one hadith section into display [BookHadith]s, shared by
/// the bundled (SQLite) and remote (network) data sources so the zip / grade /
/// English-fallback rules live in exactly one place. The data sources differ
/// only in *how* they load the raw rows; the shaping is identical.

/// Minimal projection of one hadith entry from a fawazahmed0 edition
/// (`hadiths[]` of a `{section}.min.json` file).
final class RawHadith {
  const RawHadith({
    required this.number,
    required this.text,
    required this.grade,
  });

  final int number;
  final String text;
  final String grade;

  static RawHadith? parse(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final number = map['hadithnumber'];
    final text = map['text'];
    if (number is! num || text is! String) {
      return null;
    }
    return RawHadith(
      number: number.toInt(),
      text: text.trim(),
      grade: firstGrade(map['grades']),
    );
  }

  /// Prefers an Al-Albani grading when present (the most-cited for the Sunan),
  /// otherwise the first available grade.
  static String firstGrade(Object? grades) {
    if (grades is! List || grades.isEmpty) {
      return '';
    }
    String? first;
    for (final g in grades) {
      if (g is! Map) {
        continue;
      }
      final name = g['name'];
      final grade = g['grade'];
      if (grade is! String || grade.isEmpty) {
        continue;
      }
      first ??= grade;
      if (name is String && name.toLowerCase().contains('albani')) {
        return grade;
      }
    }
    return first ?? '';
  }
}

/// One hadith from the hadithbangla repo's per-chapter file. Entries are raw
/// objects, but tolerate a `{ "hadith": {...} }` wrapper too.
final class BnHadith {
  const BnHadith({
    required this.number,
    required this.arabic,
    required this.bn,
    required this.narrator,
    required this.grade,
  });

  final int number;
  final String arabic;
  final String bn;
  final String narrator;
  final String grade;

  static BnHadith? parse(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    var map = entry.cast<String, Object?>();
    if (map['hadith'] case final Map<Object?, Object?> inner) {
      map = inner.cast<String, Object?>();
    }
    final number = map['hadith_id'];
    final bn = map['bn'];
    if (number is! num || bn is! String) {
      return null;
    }
    final ar = map['ar'];
    final narrator = map['narrator'];
    final grade = map['grade'];
    return BnHadith(
      number: number.toInt(),
      arabic: ar is String ? ar.trim() : '',
      bn: bn.trim(),
      narrator: narrator is String ? narrator.trim() : '',
      grade: grade is String ? grade.trim() : '',
    );
  }
}

/// Zips the [arabic] edition with the reader's [translation] (and an
/// [englishFallback] for gaps in a non-English edition) into display hadith.
/// [translationIsEnglish] is true when the reader's translation edition *is*
/// the English one, so no separate fallback is needed.
List<BookHadith> assembleSection({
  required HadithBook book,
  required List<RawHadith> arabic,
  required List<RawHadith> translation,
  required List<RawHadith> englishFallback,
  required bool translationIsEnglish,
}) {
  final fallback = translationIsEnglish
      ? const <int, RawHadith>{}
      : {for (final h in englishFallback) h.number: h};
  final wantsNonEnglish = !translationIsEnglish;
  final translationByNumber = {for (final h in translation) h.number: h};
  return [
    for (final ar in arabic)
      () {
        final preferred = translationByNumber[ar.number];
        final hasPreferred = preferred != null && preferred.text.isNotEmpty;
        final text = hasPreferred
            ? preferred.text
            : (fallback[ar.number]?.text ?? '');
        return BookHadith(
          number: ar.number,
          arabic: ar.text,
          translation: text,
          // Bukhari/Muslim ship no per-hadith grade because the whole book is
          // rigorously authentic — surface "Sahih" so every entry is labelled.
          grade: _grade(ar, preferred, book.isSahih),
          reference: '${book.en} ${ar.number}',
          // bn requested but only English was available for this hadith.
          fallbackTranslation:
              wantsNonEnglish && !hasPreferred && text.isNotEmpty,
        );
      }(),
  ];
}

/// Shapes one Bengali chapter (hadithbangla source) into display hadith.
List<BookHadith> assembleBangla(HadithBook book, List<BnHadith> raw) => [
      for (final h in raw)
        BookHadith(
          number: h.number,
          arabic: h.arabic,
          translation: h.bn,
          grade: h.grade.isNotEmpty ? h.grade : (book.isSahih ? 'সহিহ' : ''),
          reference: '${book.bn} ${h.number}',
          narrator: h.narrator,
        ),
    ];

String _grade(RawHadith arabic, RawHadith? translation, bool sahih) {
  if (arabic.grade.isNotEmpty) {
    return arabic.grade;
  }
  if ((translation?.grade ?? '').isNotEmpty) {
    return translation!.grade;
  }
  return sahih ? 'Sahih' : '';
}
