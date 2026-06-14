import 'dart:convert';

import '../domain/entities/hadith_book.dart';
import 'hadith_section_assembler.dart';

/// Fetches the raw body of [url] as a string. Injected so the data source
/// is testable without real network access.
typedef HttpGet = Future<String> Function(Uri url);

/// Fetches hadith section text from two open sources:
///  - English (and Arabic): fawazahmed0/hadith-api (CC0, jsDelivr CDN).
///  - Bengali: the hadithbangla repo (per-chapter Bangla translation + grade +
///    narrator) — a far better Bangla experience than fawazahmed0's `ben-*`.
/// One section = one chapter of a book.
///
/// Kept only as an online fallback now that the full text ships bundled (see
/// [HadithBookBundledDataSource]); the assembly itself is shared via
/// [assembleSection] / [assembleBangla].
final class HadithBookRemoteDataSource {
  HadithBookRemoteDataSource(this._get);

  static const _base =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';
  static const _bnBase =
      'https://raw.githubusercontent.com/azharcse14/hadithbangla/main';

  final HttpGet _get;

  // Cache by full section URL so Arabic and translation are cached separately.
  final Map<String, List<RawHadith>> _cache = {};
  final Map<String, List<BnHadith>> _bnCache = {};

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
      return assembleBangla(book, await _loadBangla(book, section));
    }
    final arabic = await _fetchEdition(book.editionAr, section.number);
    final translationEdition = book.translationEdition(languageCode);
    final translationIsEnglish = translationEdition == book.editionEn;
    // Preferred-language text. Some editions don't exist for every book (e.g.
    // no Bengali "40 Hadith Qudsi") — tolerate that and lean on the English
    // fallback rather than failing the whole section.
    final translation =
        await _fetchEditionOrEmpty(translationEdition, section.number);
    // English fallback for gaps (or wholly missing) non-English editions.
    // This one is NOT swallowed: if it also fails the section genuinely can't
    // load (offline), so the error/retry screen should show.
    final englishFallback = translationIsEnglish
        ? const <RawHadith>[]
        : await _fetchEdition(book.editionEn, section.number);
    return assembleSection(
      book: book,
      arabic: arabic,
      translation: translation,
      englishFallback: englishFallback,
      translationIsEnglish: translationIsEnglish,
    );
  }

  Future<List<BnHadith>> _loadBangla(
    HadithBook book,
    HadithSection section,
  ) async {
    final url = _bnChapterUrl(book.bnFolder, section.number);
    if (_bnCache[url.toString()] case final cached?) {
      return cached;
    }
    final body = await _get(url);
    final decoded = jsonDecode(body);
    final entries = decoded is List ? decoded : const <Object?>[];
    final parsed = [
      for (final entry in entries)
        if (BnHadith.parse(entry) case final h?) h,
    ];
    return _bnCache[url.toString()] = parsed;
  }

  /// Like [_fetchEdition] but returns an empty list instead of throwing —
  /// used for the preferred-language edition, which may not exist for a book.
  Future<List<RawHadith>> _fetchEditionOrEmpty(
    String edition,
    int section,
  ) async {
    try {
      return await _fetchEdition(edition, section);
    } on Object {
      return const [];
    }
  }

  Future<List<RawHadith>> _fetchEdition(String edition, int section) async {
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
        if (RawHadith.parse(entry) case final h?) h,
    ];
    return _cache[url.toString()] = parsed;
  }
}
