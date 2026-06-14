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

  Future<List<BookHadith>> fetchSection(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    if (book.usesBanglaSource(languageCode)) {
      return assembleBangla(book, await _bangla(book, section.number));
    }
    final arabic = await _edition(book.editionAr, section.number);
    final translationEdition = book.translationEdition(languageCode);
    final translationIsEnglish = translationEdition == book.editionEn;
    final translation = await _edition(translationEdition, section.number);
    final englishFallback = translationIsEnglish
        ? const <RawHadith>[]
        : await _edition(book.editionEn, section.number);
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
    return blob == null ? const [] : decodeEditionBlob(blob);
  }

  Future<List<BnHadith>> _bangla(HadithBook book, int section) async {
    final blob = await (await _open).banglaBlob(book.id, section);
    return blob == null ? const [] : decodeBanglaBlob(blob);
  }
}
