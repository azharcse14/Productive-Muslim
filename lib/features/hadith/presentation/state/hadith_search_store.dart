import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/hadith_search.dart';
import '../../domain/repositories/hadith_book_repository.dart';

sealed class HadithSearchState {
  const HadithSearchState();
}

/// Nothing typed yet.
final class HadithSearchIdle extends HadithSearchState {
  const HadithSearchIdle();
}

final class HadithSearchLoading extends HadithSearchState {
  const HadithSearchLoading();
}

/// Search finished; empty [results] hits = no match.
final class HadithSearchDone extends HadithSearchState {
  const HadithSearchDone(this.results);

  final HadithSearchResults results;
}

final class HadithSearchFailed extends HadithSearchState {
  const HadithSearchFailed();
}

/// Debounced full-collection hadith search for one screen.
final class HadithSearchStore {
  HadithSearchStore(
    this._repository, {
    this.debounce = const Duration(milliseconds: 300),
  });

  final HadithBookRepository _repository;
  final Duration debounce;

  late final state = signal<HadithSearchState>(const HadithSearchIdle());

  /// False until the corpus has loaded once — the screen says
  /// "Preparing search…" while a search waits on it.
  late final ready = signal(false);

  Timer? _timer;

  /// Bumped per query so a slow, stale search can't overwrite a newer one.
  var _seq = 0;
  var _disposed = false;
  var _query = '';
  var _languageCode = 'en';

  /// Starts loading the corpus (seconds on first use) while the user types.
  void warmUp(String languageCode) => unawaited(
    _repository.search('', languageCode).then((r) {
      if (!_disposed && r.isSuccess) {
        ready.value = true;
      }
    }),
  );

  /// Runs [query] after [debounce] of no further input.
  void search(String query, String languageCode) {
    _query = query;
    _languageCode = languageCode;
    _timer?.cancel();
    final seq = ++_seq;
    if (query.trim().isEmpty) {
      state.value = const HadithSearchIdle();
      return;
    }
    _timer = Timer(debounce, () => unawaited(_run(seq)));
  }

  /// Re-runs the last query now (after a failure).
  Future<void> retry() => _run(++_seq);

  Future<void> _run(int seq) async {
    state.value = const HadithSearchLoading();
    final result = await _repository.search(_query, _languageCode);
    if (_disposed || seq != _seq) {
      return;
    }
    if (result.isSuccess) {
      ready.value = true;
    }
    state.value = switch (result.valueOrNull) {
      final results? => HadithSearchDone(results),
      null => const HadithSearchFailed(),
    };
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    state.dispose();
    ready.dispose();
    _repository.releaseSearch();
  }
}
