import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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
}
