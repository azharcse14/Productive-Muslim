import 'dart:isolate';

import '../domain/entities/hadith_book.dart';
import 'hadith_blob_codec.dart';
import 'hadith_database.dart';
import 'hadith_section_assembler.dart';

/// Serves hadith section text from the bundled SQLite snapshot
/// ([HadithDatabase]) — the offline-first primary source. Mirrors
/// [HadithBookRemoteDataSource] exactly: only the row loading differs (DB vs
/// network); the shaping is the shared [assembleSection] / [assembleBangla].
final class HadithBookBundledDataSource {
  /// Takes a [Future] so the bundled asset is copied lazily on the first read
  /// rather than blocking app startup (the future resolves once and is reused).
  HadithBookBundledDataSource(this._open);

  final Future<HadithDatabase> _open;

  /// Recently assembled sections (insertion-ordered map as an LRU), so
  /// flipping back and forth between chapters doesn't re-decode them.
  static const _cacheSize = 4;
  final Map<String, List<BookHadith>> _cache = {};

  Future<List<BookHadith>> fetchSection(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    final key = '${book.id}/${section.number}/$languageCode';
    if (_cache.remove(key) case final cached?) {
      return _cache[key] = cached; // re-insert as most recent
    }
    final result = await _load(book, section, languageCode);
    _cache[key] = result;
    if (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return result;
  }

  Future<List<BookHadith>> _load(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    if (book.usesBanglaSource(languageCode)) {
      return assembleBangla(book, await _bangla(book, section.number));
    }
    final translationEdition = book.translationEdition(languageCode);
    final translationIsEnglish = translationEdition == book.editionEn;
    // The three decodes are independent isolates: run them in parallel.
    final (arabic, translation, englishFallback) = await (
      _edition(book.editionAr, section.number),
      _edition(translationEdition, section.number),
      translationIsEnglish
          ? Future.value(const <RawHadith>[])
          : _edition(book.editionEn, section.number),
    ).wait;
    return assembleSection(
      book: book,
      arabic: arabic,
      translation: translation,
      englishFallback: englishFallback,
      translationIsEnglish: translationIsEnglish,
    );
  }

  Future<List<RawHadith>> _edition(String edition, int section) async {
    final blob = await (await _open).editionBlob(edition, section);
    // Sections run to ~1.8 MB of JSON: decode off the UI thread.
    return blob == null
        ? const []
        : await Isolate.run(() => decodeEditionBlob(blob));
  }

  Future<List<BnHadith>> _bangla(HadithBook book, int section) async {
    final blob = await (await _open).banglaBlob(book.id, section);
    return blob == null
        ? const []
        : await Isolate.run(() => decodeBanglaBlob(blob));
  }
}
