import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_search.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_book_repository.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_search_store.dart';

/// Each search waits on its own completer, so tests pick the finish order.
final class _ManualRepository implements HadithBookRepository {
  final pending = <String, Completer<Result<HadithSearchResults>>>{};

  @override
  Future<Result<List<HadithBook>>> books() async => const Result.success([]);

  @override
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async => const Result.success([]);

  @override
  Future<Result<HadithSearchResults>> search(
    String query,
    String languageCode, {
    int limit = hadithSearchLimit,
  }) => (pending[query] = Completer()).future;

  @override
  void releaseSearch() {}
}

Result<HadithSearchResults> _results({required bool truncated}) =>
    Result.success((hits: const [], truncated: truncated));

void main() {
  test('a slow older query never overwrites a newer one', () async {
    final repo = _ManualRepository();
    final store = HadithSearchStore(repo, debounce: Duration.zero);
    addTearDown(store.dispose);

    store.search('old', 'en');
    await pumpEventQueue();
    store.search('new', 'en');
    await pumpEventQueue();
    expect(repo.pending.keys, ['old', 'new']);

    repo.pending['new']!.complete(_results(truncated: true));
    await pumpEventQueue();
    repo.pending['old']!.complete(_results(truncated: false));
    await pumpEventQueue();

    final state = store.state.value;
    expect(state, isA<HadithSearchDone>());
    expect((state as HadithSearchDone).results.truncated, isTrue);
    expect(store.ready.value, isTrue);
  });

  test('clearing the query cancels the pending search', () async {
    final repo = _ManualRepository();
    final store = HadithSearchStore(repo, debounce: Duration.zero);
    addTearDown(store.dispose);

    store.search('old', 'en');
    await pumpEventQueue();
    store.search(' ', 'en');
    repo.pending['old']!.complete(_results(truncated: false));
    await pumpEventQueue();
    expect(store.state.value, isA<HadithSearchIdle>());
  });
}
