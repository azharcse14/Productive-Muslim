import '../../../config/app_config.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/hadith_book.dart';
import '../domain/repositories/hadith_book_repository.dart';
import 'hadith_book_bundled_data_source.dart';
import 'hadith_book_catalog_data_source.dart';
import 'hadith_book_remote_data_source.dart';

final class HadithBookRepositoryImpl implements HadithBookRepository {
  /// [bengaliHadith] false (or a bundled DB without the hadithbangla table)
  /// drops that source everywhere: Bengali readers get Arabic + English and
  /// the hadithbangla URL is never requested.
  HadithBookRepositoryImpl(
    this._catalog,
    this._bundled,
    this._remote, {
    bool bengaliHadith = AppConfig.bengaliHadith,
  }) : _bengaliHadith = bengaliHadith;

  final HadithBookCatalogDataSource _catalog;
  final HadithBookBundledDataSource _bundled;
  final HadithBookRemoteDataSource _remote;
  final bool _bengaliHadith;
  bool? _hasBangla;

  /// Whether the hadithbangla source may be used. The DB probe is cached once
  /// it succeeds; if the DB can't be opened, the build flag alone decides.
  Future<bool> _banglaAllowed() async {
    if (!_bengaliHadith) {
      return false;
    }
    if (_hasBangla case final known?) {
      return known;
    }
    try {
      return _hasBangla = await _bundled.hasBangla();
    } on Object {
      return true;
    }
  }

  Future<HadithBook> _effective(HadithBook book) async =>
      await _banglaAllowed() ? book : book.withoutBanglaSource();

  @override
  Future<Result<List<HadithBook>>> books() async {
    try {
      final books = await _catalog.loadBooks();
      if (await _banglaAllowed()) {
        return Result.success(books);
      }
      return Result.success([for (final b in books) b.withoutBanglaSource()]);
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
    book = await _effective(book);
    // Offline-first: the bundled snapshot is the source of truth. Only if it
    // can't serve this section (a gap, or a future book not yet snapshotted)
    // do we reach for the network — so a deleted upstream source never breaks
    // the reader.
    try {
      final items = await _bundled.fetchSection(book, section, languageCode);
      if (items.isNotEmpty) {
        return Result.success(items);
      }
    } on Object {
      // fall through to the remote fallback
    }
    try {
      final items = await _remote.fetchSection(book, section, languageCode);
      return Result.success(items);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Hadith section fetch failed', e));
    }
  }
}
