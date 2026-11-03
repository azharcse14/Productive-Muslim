import 'dart:async';

import '../../../config/app_config.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/hadith_book.dart';
import '../domain/entities/hadith_search.dart';
import '../domain/repositories/hadith_book_repository.dart';
import 'hadith_book_bundled_data_source.dart';
import 'hadith_book_catalog_data_source.dart';
import 'hadith_book_remote_data_source.dart';
import 'hadith_search.dart';
import 'hadith_search_worker.dart';

final class HadithBookRepositoryImpl implements HadithBookRepository {
  /// [bengaliHadith] false (or a bundled DB without the hadithbangla table)
  /// drops that source everywhere: Bengali readers get Arabic + English and
  /// the hadithbangla URL is never requested.
  ///
  /// [openSearch] (tests) replaces the bundled search worker; the loaded
  /// search corpus outlives [releaseSearch] by [searchKeepAlive].
  HadithBookRepositoryImpl(
    this._catalog,
    this._bundled,
    this._remote, {
    bool bengaliHadith = AppConfig.bengaliHadith,
    Future<HadithSearchIndex> Function(List<HadithBook>)? openSearch,
    this.searchKeepAlive = const Duration(seconds: 60),
  }) : _bengaliHadith = bengaliHadith,
       _openSearch = openSearch;

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
      return Result.failure(
        UnexpectedFailure('Hadith section fetch failed', e),
      );
    }
  }

  final Future<HadithSearchIndex> Function(List<HadithBook>)? _openSearch;
  final Duration searchKeepAlive;

  /// The loaded (or loading) search index and the books its hits index.
  Future<(List<HadithBook>, HadithSearchIndex)>? _search;
  Timer? _release;

  @override
  Future<Result<HadithSearchResults>> search(
    String query,
    String languageCode, {
    int limit = hadithSearchLimit,
  }) async {
    _release?.cancel();
    final loading = _search ??= _loadSearch();
    final List<HadithBook> books;
    final HadithSearchIndex index;
    try {
      (books, index) = await loading;
    } on Object catch (e) {
      if (identical(_search, loading)) {
        _search = null; // retry the load next time
      }
      return Result.failure(UnexpectedFailure('Hadith search load failed', e));
    }
    try {
      final raw = await index.search(query, languageCode, limit);
      return Result.success((
        hits: toSearchHits(books, raw.hits),
        truncated: raw.truncated,
      ));
    } on Object catch (e) {
      // The corpus is fine; only this query failed.
      return Result.failure(UnexpectedFailure('Hadith search failed', e));
    }
  }

  Future<(List<HadithBook>, HadithSearchIndex)> _loadSearch() async {
    final books = (await this.books()).valueOrNull;
    if (books == null) {
      throw StateError('Hadith catalog unavailable');
    }
    return (books, await (_openSearch ?? _bundled.openSearch)(books));
  }

  /// Frees the corpus after [searchKeepAlive] unless searched again, so
  /// reopening the search screen soon after is instant.
  @override
  void releaseSearch() {
    _release?.cancel();
    _release = Timer(searchKeepAlive, () {
      final loaded = _search;
      _search = null;
      if (loaded != null) {
        // A failed load has nothing to close.
        unawaited(loaded.then((s) => s.$2.close(), onError: (Object _) {}));
      }
    });
  }
}
