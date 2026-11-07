import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/dua.dart';

/// Favorited dua ids, persisted as a string list under [_key].
final class DuaFavoritesStore {
  DuaFavoritesStore(this._prefs);

  static const _key = 'dua_favorites_v1';

  final SharedPreferencesAsync _prefs;

  late final ids = signal(const <String>{});
  late final loaded = signal(false);

  /// The last load failed: the stored list is unknown (not empty), so the
  /// screen offers a retry and [toggle] won't write over it.
  late final failed = signal(false);

  Future<void>? _loading;

  /// Restores persisted favorite ids; ids of removed duplicate duas resolve
  /// to the entry that was kept. Concurrent callers share one read; never
  /// throws (a failure sets [failed]).
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    try {
      final stored = await _prefs.getStringList(_key);
      if (stored != null) {
        ids.value = {for (final id in stored) duaIdAliases[id] ?? id};
      }
      failed.value = false;
      loaded.value = true;
    } on Object catch (e) {
      debugPrint('Dua favorites load failed: $e');
      failed.value = true;
    }
  }

  bool isFavorite(String id) => ids.value.contains(id);

  /// Adds or removes [id], updating the signal immediately then persisting.
  /// Returns false (and takes the change back) when it couldn't be saved.
  Future<bool> toggle(String id) async {
    // Writing before the stored list is read would overwrite it.
    if (!loaded.value) {
      await load();
      if (!loaded.value) {
        return false;
      }
    }
    final next = Set<String>.from(ids.value);
    final added = next.add(id);
    if (!added) {
      next.remove(id);
    }
    ids.value = next;
    try {
      await _prefs.setStringList(_key, next.toList());
      return true;
    } on Object catch (e) {
      debugPrint('Dua favorite save failed: $e');
      // Undo just this id: another toggle may have landed meanwhile.
      final reverted = Set<String>.from(ids.value);
      if (added) {
        reverted.remove(id);
      } else {
        reverted.add(id);
      }
      ids.value = reverted;
      return false;
    }
  }
}
