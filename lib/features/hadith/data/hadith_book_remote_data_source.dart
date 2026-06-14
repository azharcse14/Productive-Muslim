import 'dart:convert';

import '../domain/entities/hadith_book.dart';

/// Fetches the raw body of [url] as a string. Injected so the data source
/// is testable without real network access.
typedef HttpGet = Future<String> Function(Uri url);

/// Fetches hadith section text from two open sources:
///  - English (and Arabic): fawazahmed0/hadith-api (CC0, jsDelivr CDN).
///  - Bengali: the hadithbangla repo (per-chapter Bangla translation + grade +
///    narrator) — a far better Bangla experience than fawazahmed0's `ben-*`.
/// One section = one chapter of a book.
final class HadithBookRemoteDataSource {
  HadithBookRemoteDataSource(this._get);

  static const _base =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';
  static const _bnBase =
      'https://raw.githubusercontent.com/azharcse14/hadithbangla/main';

  final HttpGet _get;

  // Cache by full section URL so Arabic and translation are cached separately.
  final Map<String, List<_RawHadith>> _cache = {};
  final Map<String, List<_BnHadith>> _bnCache = {};

  Uri _sectionUrl(String edition, int section) =>
      Uri.parse('$_base/$edition/sections/$section.min.json');

  Uri _bnChapterUrl(String folder, int chapter) =>
      Uri.parse('$_bnBase/$folder/Chapter/$chapter.json');

  /// Arabic + translation for one [section] of [book], zipped by hadith
  /// number. Translation falls back to English if the reader's language
  /// edition has no entry for a hadith.
  Future<List<BookHadith>> fetchSection(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    if (book.usesBanglaSource(languageCode)) {
      return _fetchBangla(book, section);
    }
    final arabic = await _fetchEdition(book.editionAr, section.number);
    final translationEdition = book.translationEdition(languageCode);
    // Preferred-language text. Some editions don't exist for every book (e.g.
    // no Bengali "40 Hadith Qudsi") — tolerate that and lean on the English
    // fallback rather than failing the whole section.
    final translation =
        await _fetchEditionOrEmpty(translationEdition, section.number);
    // English fallback for gaps (or wholly missing) non-English editions.
    // This one is NOT swallowed: if it also fails the section genuinely can't
    // load (offline), so the error/retry screen should show.
    final fallback = translationEdition == book.editionEn
        ? const <int, _RawHadith>{}
        : {
            for (final h in await _fetchEdition(book.editionEn, section.number))
              h.number: h,
          };

    final wantsNonEnglish = translationEdition != book.editionEn;
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
            // Bukhari/Muslim ship no per-hadith grade because the whole book
            // is rigorously authentic — surface "Sahih" so every entry is
            // labelled.
            grade: _grade(ar, preferred, book.isSahih),
            reference: '${book.en} ${ar.number}',
            // bn requested but only English was available for this hadith.
            fallbackTranslation:
                wantsNonEnglish && !hasPreferred && text.isNotEmpty,
          );
        }(),
    ];
  }

  /// One Bengali chapter from the hadithbangla repo — Arabic + Bangla
  /// translation + Bangla narrator + Bangla grade, all from a single fetch.
  Future<List<BookHadith>> _fetchBangla(
    HadithBook book,
    HadithSection section,
  ) async {
    final url = _bnChapterUrl(book.bnFolder, section.number);
    final raw = _bnCache[url.toString()] ?? await _loadBangla(url);
    return [
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
  }

  Future<List<_BnHadith>> _loadBangla(Uri url) async {
    final body = await _get(url);
    final decoded = jsonDecode(body);
    final entries = decoded is List ? decoded : const <Object?>[];
    final parsed = [
      for (final entry in entries)
        if (_BnHadith.parse(entry) case final h?) h,
    ];
    return _bnCache[url.toString()] = parsed;
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

  /// Like [_fetchEdition] but returns an empty list instead of throwing —
  /// used for the preferred-language edition, which may not exist for a book.
  Future<List<_RawHadith>> _fetchEditionOrEmpty(
    String edition,
    int section,
  ) async {
    try {
      return await _fetchEdition(edition, section);
    } on Object {
      return const [];
    }
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

/// One hadith from the hadithbangla repo's per-chapter file. Entries are raw
/// objects, but tolerate a `{ "hadith": {...} }` wrapper too.
final class _BnHadith {
  const _BnHadith({
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

  static _BnHadith? parse(Object? entry) {
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
    return _BnHadith(
      number: number.toInt(),
      arabic: ar is String ? ar.trim() : '',
      bn: bn.trim(),
      narrator: narrator is String ? narrator.trim() : '',
      grade: grade is String ? grade.trim() : '',
    );
  }
}
