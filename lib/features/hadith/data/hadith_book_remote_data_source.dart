import 'dart:convert';

import '../domain/entities/hadith_book.dart';

/// Fetches the raw body of [url] as a string. Injected so the data source
/// is testable without real network access.
typedef HttpGet = Future<String> Function(Uri url);

/// Fetches hadith section text from the fawazahmed0/hadith-api dataset
/// (CC0, mirrored on the jsDelivr CDN). One section = one chapter of a book.
final class HadithBookRemoteDataSource {
  HadithBookRemoteDataSource(this._get);

  static const _base =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  final HttpGet _get;

  // Cache by full section URL so Arabic and translation are cached separately.
  final Map<String, List<_RawHadith>> _cache = {};

  Uri _sectionUrl(String edition, int section) =>
      Uri.parse('$_base/$edition/sections/$section.min.json');

  /// Arabic + translation for one [section] of [book], zipped by hadith
  /// number. Translation falls back to English if the reader's language
  /// edition has no entry for a hadith.
  Future<List<BookHadith>> fetchSection(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    final arabic = await _fetchEdition(book.editionAr, section.number);
    final translationEdition = book.translationEdition(languageCode);
    final translation =
        await _fetchEdition(translationEdition, section.number);
    // English fallback for any gaps in a non-English translation edition.
    final fallback = translationEdition == book.editionEn
        ? const <int, _RawHadith>{}
        : {
            for (final h in await _fetchEdition(book.editionEn, section.number))
              h.number: h,
          };

    final translationByNumber = {for (final h in translation) h.number: h};
    return [
      for (final ar in arabic)
        BookHadith(
          number: ar.number,
          arabic: ar.text,
          translation:
              (translationByNumber[ar.number] ?? fallback[ar.number])?.text ??
                  '',
          // Bukhari/Muslim ship no per-hadith grade because the whole book is
          // rigorously authentic — surface "Sahih" so every entry is labelled.
          grade: _grade(ar, translationByNumber[ar.number], book.isSahih),
          reference: '${book.en} ${ar.number}',
        ),
    ];
  }

  static String _grade(_RawHadith arabic, _RawHadith? translation, bool sahih) {
    if (arabic.grade.isNotEmpty) {
      return arabic.grade;
    }
    if ((translation?.grade ?? '').isNotEmpty) {
      return translation!.grade;
    }
    return sahih ? 'Sahih' : '';
  }

  Future<List<_RawHadith>> _fetchEdition(String edition, int section) async {
    final url = _sectionUrl(edition, section);
    if (_cache[url.toString()] case final cached?) {
      return cached;
    }
    final body = await _get(url);
    final decoded = jsonDecode(body);
    final root = decoded is Map ? decoded.cast<String, Object?>() : null;
    final entries = switch (root?['hadiths']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    final parsed = [
      for (final entry in entries)
        if (_RawHadith.parse(entry) case final h?) h,
    ];
    return _cache[url.toString()] = parsed;
  }
}

/// Minimal projection of one hadith entry from the dataset.
final class _RawHadith {
  const _RawHadith({
    required this.number,
    required this.text,
    required this.grade,
  });

  final int number;
  final String text;
  final String grade;

  static _RawHadith? parse(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final number = map['hadithnumber'];
    final text = map['text'];
    if (number is! num || text is! String) {
      return null;
    }
    return _RawHadith(
      number: number.toInt(),
      text: text.trim(),
      grade: _firstGrade(map['grades']),
    );
  }

  /// Prefers an Al-Albani grading when present (the most-cited for the Sunan),
  /// otherwise the first available grade.
  static String _firstGrade(Object? grades) {
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
