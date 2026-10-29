import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/quran/domain/entities/ayah.dart';
import 'package:productive_muslim/features/quran/domain/entities/surah.dart';
import 'package:productive_muslim/features/quran/domain/repositories/quran_repository.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Repository whose bookmark reads/writes block on test-controlled gates.
final class _GatedRepo implements QuranRepository {
  int surahCalls = 0;
  final stored = <int>{};
  Completer<void>? readGate;
  final writes = <Completer<bool>>[];

  @override
  Future<Result<List<Surah>>> surahs() async {
    surahCalls++;
    return const Result.success([]);
  }

  @override
  Future<Result<QuranPosition?>> lastRead() async =>
      const Result.success(null);

  @override
  Future<Result<Set<int>>> bookmarkedAyahIds() async {
    final snapshot = {...stored};
    await readGate?.future;
    return Result.success(snapshot);
  }

  @override
  Future<Result<void>> toggleBookmark(int ayahId) async {
    final gate = Completer<bool>();
    writes.add(gate);
    if (!await gate.future) {
      return const Result.failure(UnexpectedFailure('write failed'));
    }
    if (!stored.remove(ayahId)) {
      stored.add(ayahId);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setLastRead(QuranPosition position) async =>
      const Result.success(null);

  @override
  Future<Result<List<Ayah>>> ayahsOf(int surah) async =>
      const Result.success([]);

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) async =>
      const Result.success([]);
}

void main() {
  late _GatedRepo repo;
  late QuranStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repo = _GatedRepo();
    store = QuranStore(repo, SharedPreferencesAsync());
  });

  test('concurrent loads share one pass and keep a bookmark made meanwhile',
      () async {
    repo.readGate = Completer();
    final first = store.load();
    final second = store.load();
    await pumpEventQueue();

    final tap = store.toggleBookmark(5); // lands while the load is reading
    repo.writes.single.complete(true);
    await tap;
    repo.readGate!.complete();
    await Future.wait([first, second]);

    expect(repo.surahCalls, 1);
    expect(store.bookmarks.value, {5});
    expect(store.loaded.value, isTrue);

    await store.load(); // a later call (Retry) still reloads
    expect(repo.surahCalls, 2);
  });

  test('a failed write undoes only its own tap', () async {
    await store.load();
    final firstTap = store.toggleBookmark(7); // add — will fail
    final secondTap = store.toggleBookmark(7); // remove — will succeed
    repo.writes[1].complete(true);
    await secondTap;
    repo.writes[0].complete(false);
    await firstTap;

    // DB: the failed add never happened, the remove flipped it → {7}.
    expect(repo.stored, {7});
    expect(store.bookmarks.value, {7});
  });
}
