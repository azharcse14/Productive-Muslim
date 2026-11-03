import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_bundled_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_catalog_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_remote_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_repository_impl.dart';
import 'package:productive_muslim/features/hadith/data/hadith_search.dart';
import 'package:productive_muslim/features/hadith/data/hadith_search_worker.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';

final class _Bundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '''
{"books": [{"id": "bukhari", "en": "Sahih al-Bukhari", "bn": "",
  "author": "", "kind": "sahih", "total": 7,
  "edition_ar": "ara-bukhari", "edition_en": "eng-bukhari",
  "edition_bn": "ben-bukhari",
  "sections": [{"n": 1, "name": "Revelation", "first": 1, "last": 7}]}]}
''';
}

final class _FakeIndex implements HadithSearchIndex {
  bool failSearch = false;
  bool closed = false;

  @override
  Future<HadithRawResults> search(String query, String lang, int limit) async {
    if (failSearch) {
      throw StateError('query broke');
    }
    return (
      hits: [
        (
          book: 0,
          section: 1,
          bn: false,
          number: 3,
          snippet: query,
          start: 0,
          end: 0,
        ),
        // Chapter the catalog doesn't list: dropped.
        (
          book: 0,
          section: 99,
          bn: false,
          number: 4,
          snippet: query,
          start: 0,
          end: 0,
        ),
      ],
      truncated: false,
    );
  }

  @override
  void close() => closed = true;
}

void main() {
  late List<Completer<HadithSearchIndex>> opens;

  HadithBookRepositoryImpl repo() => HadithBookRepositoryImpl(
    HadithBookCatalogDataSource(_Bundle()),
    HadithBookBundledDataSource(() => throw UnimplementedError()),
    HadithBookRemoteDataSource((_) => throw UnimplementedError()),
    bengaliHadith: false,
    openSearch: (List<HadithBook> books) {
      final c = Completer<HadithSearchIndex>();
      opens.add(c);
      return c.future;
    },
    searchKeepAlive: const Duration(milliseconds: 20),
  );

  setUp(() => opens = []);

  test('a failed load is retried; hits resolve to catalog chapters', () async {
    final r = repo();
    final first = r.search('x', 'en');
    await pumpEventQueue();
    opens.single.completeError(StateError('disk'));
    expect((await first).isSuccess, isFalse);

    final second = r.search('prayer', 'en');
    await pumpEventQueue();
    expect(opens, hasLength(2));
    opens.last.complete(_FakeIndex());
    final hits = (await second).valueOrNull!.hits;
    expect(
      [for (final h in hits) (h.section.name, h.number)],
      [('Revelation', 3)],
    );
  });

  test('a failed query keeps the loaded corpus', () async {
    final r = repo();
    final index = _FakeIndex()..failSearch = true;
    final first = r.search('x', 'en');
    await pumpEventQueue();
    opens.single.complete(index);
    expect((await first).isSuccess, isFalse);

    index.failSearch = false;
    expect((await r.search('x', 'en')).isSuccess, isTrue);
    expect(opens, hasLength(1));
  });

  test('release then reopen reuses the in-flight load', () async {
    final r = repo();
    final warm = r.search('', 'en');
    await pumpEventQueue();
    r.releaseSearch(); // screen closed mid-load
    final again = r.search('x', 'en'); // reopened before the keep-alive
    await pumpEventQueue();
    final index = _FakeIndex();
    opens.single.complete(index);
    expect((await warm).isSuccess, isTrue);
    expect((await again).isSuccess, isTrue);
    expect(opens, hasLength(1));

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(index.closed, isFalse, reason: 'search cancelled the release');
  });

  test('the corpus is closed after the keep-alive', () async {
    final r = repo();
    final first = r.search('x', 'en');
    await pumpEventQueue();
    final index = _FakeIndex();
    opens.single.complete(index);
    await first;

    r.releaseSearch();
    expect(index.closed, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(index.closed, isTrue);

    final reopened = r.search('x', 'en');
    await pumpEventQueue();
    expect(opens, hasLength(2));
    opens.last.complete(_FakeIndex());
    expect((await reopened).isSuccess, isTrue);
  });
}
