import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Favorited dua ids, persisted as a string list under [_key].
final class DuaFavoritesStore {
  DuaFavoritesStore(this._prefs);

  static const _key = 'dua_favorites_v1';

  final SharedPreferencesAsync _prefs;

  late final ids = signal(const <String>{});
  late final loaded = signal(false);

  /// Restores persisted favorite ids.
  Future<void> load() async {
    final stored = await _prefs.getStringList(_key);
    if (stored != null) {
      ids.value = stored.toSet();
    }
    loaded.value = true;
  }

  bool isFavorite(String id) => ids.value.contains(id);

  /// Adds or removes [id], updating the signal immediately then persisting.
  Future<void> toggle(String id) async {
    // Writing before the stored list is read would overwrite it.
    if (!loaded.value) {
      await load();
    }
    final next = Set<String>.from(ids.value);
    if (!next.add(id)) {
      next.remove(id);
    }
    ids.value = next;
    await _prefs.setStringList(_key, next.toList());
  }
}
