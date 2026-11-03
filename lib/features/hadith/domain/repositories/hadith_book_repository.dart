import '../../../../core/utils/result.dart';
import '../entities/hadith_book.dart';
import '../entities/hadith_search.dart';

/// Catalog of full hadith collections + on-demand section fetching.
abstract interface class HadithBookRepository {
  /// The bundled catalog of books (offline).
  Future<Result<List<HadithBook>>> books();

  /// The hadith of one [section] of [book], with Arabic + translation in
  /// [languageCode]. Network-backed; cached per (book, section, language).
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  );

  /// Searches the English and Bangla text of every bundled book for
  /// [query] (case-insensitive substring); an all-digit query (Bangla digits
  /// too) looks up that hadith number in each book instead. [languageCode]'s
  /// text ranks first. The first call loads the corpus into memory.
  Future<Result<HadithSearchResults>> search(
    String query,
    String languageCode, {
    int limit = hadithSearchLimit,
  });

  /// Drops the in-memory search corpus (tens of MB) loaded by [search].
  void releaseSearch();
}
