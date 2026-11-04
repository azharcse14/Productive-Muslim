import '../domain/entities/hadith_book.dart';

/// The whole-number part of a displayed reference ("17a" → 17); [number]
/// when [ref] is empty or has no leading digits.
int referenceNumberOf(String ref, int number) =>
    int.tryParse(RegExp(r'^\d+').stringMatch(ref) ?? '') ?? number;

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
    this.ref = '',
  });

  final int number;
  final String text;
  final String grade;

  /// Standard (sunnah.com-style) reference number when it differs from
  /// [number] — e.g. Sahih Muslim's sequential 93 is "8a" (Abd al-Baqi).
  /// Empty when [number] already is the standard reference.
  final String ref;

  /// The whole number readers look up: [ref]'s ("8a" → 8), else [number].
  int get referenceNumber => referenceNumberOf(ref, number);

  /// False for upstream's internal number ("#1220": Sahih Muslim hadith with
  /// no Abd al-Baqi number) — it would collide with the standard 1220, so
  /// "go to number" and number search must not match it.
  bool get hasStandardNumber => !ref.startsWith('#');

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
      ref: standardRef(map['arabicnumber'], number),
    );
  }

  /// The displayed reference when it differs from the whole [number]:
  ///  * a fractional [number] is upstream's sub-narration under one number
  ///    (Bukhari 402.2 "as above", Tirmidhi 3604.02) — kept as is, so it
  ///    reads apart from 402;
  ///  * else upstream `arabicnumber` ("8.01" = 8a, "8.02" = 8b, "9" = 9) as a
  ///    sunnah.com-style reference; '' when absent or equal to [number].
  static String standardRef(Object? arabicNumber, num number) {
    if (number != number.truncate()) {
      return '$number';
    }
    final raw = switch (arabicNumber) {
      final String s => s.trim(),
      final num n => '${n.truncate()}',
      _ => '',
    };
    final parts = raw.split('.');
    if (raw.isEmpty || parts.first == '${number.toInt()}') {
      return '';
    }
    if (parts.length == 2) {
      final variant = int.tryParse(parts[1]) ?? 0;
      if (variant < 1 || variant > 26) {
        return raw;
      }
      return parts.first + String.fromCharCode(0x60 + variant); // 1 -> a
    }
    return raw;
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
      ? const <(int, int), RawHadith>{}
      : _byOccurrence(englishFallback);
  final wantsNonEnglish = !translationIsEnglish;
  final translationByKey = _byOccurrence(translation);
  final arabicSeen = <int, int>{};
  return [
    for (final ar in arabic)
      () {
        final key = (ar.number, _nextOccurrence(arabicSeen, ar.number));
        final preferred = translationByKey[key];
        final hasPreferred = preferred != null && preferred.text.isNotEmpty;
        final text = hasPreferred
            ? preferred.text
            : (fallback[key]?.text ?? '');
        return BookHadith(
          number: ar.number,
          arabic: ar.text,
          translation: text,
          // Bukhari/Muslim ship no per-hadith grade because the whole book is
          // rigorously authentic — surface "Sahih" so every entry is labelled.
          grade: _grade(ar, preferred, book.isSahih),
          reference: '${book.en} ${ar.ref.isNotEmpty ? ar.ref : ar.number}',
          referenceNumber: ar.referenceNumber,
          // bn requested but only English was available for this hadith.
          fallbackTranslation:
              wantsNonEnglish && !hasPreferred && text.isNotEmpty,
        );
      }(),
  ];
}

/// Upstream sometimes gives several distinct narrations the same hadith
/// number within a section (e.g. Tirmidhi 3604 ×10). Editions list them in
/// the same order, so key by (number, nth occurrence) — keying by number alone
/// would pair every one of them with the last translation.
Map<(int, int), RawHadith> _byOccurrence(List<RawHadith> hadiths) {
  final seen = <int, int>{};
  return {
    for (final h in hadiths) (h.number, _nextOccurrence(seen, h.number)): h,
  };
}

int _nextOccurrence(Map<int, int> seen, int number) =>
    seen[number] = (seen[number] ?? -1) + 1;

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
