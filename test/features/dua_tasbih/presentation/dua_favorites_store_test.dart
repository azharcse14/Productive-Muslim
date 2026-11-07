import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Prefs whose list writes fail (full disk, platform error).
final class _FailingListPrefs extends InMemorySharedPreferencesAsync {
  _FailingListPrefs() : super.empty();

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) => Future.error(StateError('disk full'));
}

/// Prefs whose list reads fail until [readable] flips.
final class _FlakyReadPrefs extends InMemorySharedPreferencesAsync {
  _FlakyReadPrefs() : super.empty();

  bool readable = false;

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) => readable
      ? super.getStringList(key, options)
      : Future.error(StateError('read failed'));
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('toggle adds then removes an id', () async {
    final store = DuaFavoritesStore(SharedPreferencesAsync());
    await store.load();

    expect(store.isFavorite('me_1'), isFalse);

    await store.toggle('me_1');
    expect(store.isFavorite('me_1'), isTrue);
    expect(store.ids.value, contains('me_1'));

    await store.toggle('me_1');
    expect(store.isFavorite('me_1'), isFalse);
    expect(store.ids.value, isNot(contains('me_1')));
  });

  test('load() restores persisted ids', () async {
    final first = DuaFavoritesStore(SharedPreferencesAsync());
    await first.load();
    await first.toggle('me_1');
    await first.toggle('sl_1');

    final second = DuaFavoritesStore(SharedPreferencesAsync());
    expect(second.loaded.value, isFalse);
    await second.load();

    expect(second.loaded.value, isTrue);
    expect(second.ids.value, {'me_1', 'sl_1'});
  });

  test(
    'a stored id of a removed duplicate dua resolves to the kept one',
    () async {
      await SharedPreferencesAsync().setStringList('dua_favorites_v1', [
        'tv_safar',
        'dua_safar',
      ]);
      final store = DuaFavoritesStore(SharedPreferencesAsync());
      await store.load();

      expect(store.ids.value, {'dua_safar'});

      await store.toggle('dua_safar');
      expect(
        await SharedPreferencesAsync().getStringList('dua_favorites_v1'),
        isEmpty,
      );
      await store.toggle('dua_safar');
      expect(await SharedPreferencesAsync().getStringList('dua_favorites_v1'), [
        'dua_safar',
      ]);
    },
  );

  test('a failed save rolls the toggle back and reports it', () async {
    SharedPreferencesAsyncPlatform.instance = _FailingListPrefs();
    final store = DuaFavoritesStore(SharedPreferencesAsync());
    await store.load();

    expect(await store.toggle('me_1'), isFalse);
    expect(store.isFavorite('me_1'), isFalse);
  });

  test('a failed load is flagged and toggle never writes over the stored '
      'list', () async {
    final prefs = _FlakyReadPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    await SharedPreferencesAsync().setStringList('dua_favorites_v1', ['sl_1']);
    final store = DuaFavoritesStore(SharedPreferencesAsync());

    await store.load(); // doesn't throw
    expect(store.failed.value, isTrue);
    expect(store.loaded.value, isFalse);

    expect(await store.toggle('me_1'), isFalse);
    prefs.readable = true;
    expect(await SharedPreferencesAsync().getStringList('dua_favorites_v1'), [
      'sl_1',
    ]);

    expect(await store.toggle('me_1'), isTrue); // retries the load first
    expect(store.failed.value, isFalse);
    expect(store.ids.value, {'sl_1', 'me_1'});
  });
}
