import '../../../../core/utils/result.dart';
import '../entities/hadith_book.dart';

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
}
