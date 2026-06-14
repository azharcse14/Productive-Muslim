import '../../../core/utils/result.dart';
import '../domain/entities/hadith_book.dart';
import '../domain/repositories/hadith_book_repository.dart';
import 'hadith_book_catalog_data_source.dart';
import 'hadith_book_remote_data_source.dart';

final class HadithBookRepositoryImpl implements HadithBookRepository {
  const HadithBookRepositoryImpl(this._catalog, this._remote);

  final HadithBookCatalogDataSource _catalog;
  final HadithBookRemoteDataSource _remote;

  @override
  Future<Result<List<HadithBook>>> books() async {
    try {
      return Result.success(await _catalog.loadBooks());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Hadith catalog load failed', e));
    }
  }

  @override
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    try {
      final items = await _remote.fetchSection(book, section, languageCode);
      return Result.success(items);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Hadith section fetch failed', e));
    }
  }
}
