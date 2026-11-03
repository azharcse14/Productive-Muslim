import 'package:signals_flutter/signals_flutter.dart';

import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';

/// Read-only state for the bundled hadith collection.
final class HadithStore {
  HadithStore(this._repository);

  final HadithRepository _repository;

  late final items = signal(const <Hadith>[]);
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  /// Favorited [Hadith.id]s.
  late final favorites = signal(const <String>{});

  /// Bumped by [toggleFavorite] so a load racing it keeps the tap.
  int _favoriteEdits = 0;

  /// Hadith grouped by [Hadith.topic], in first-seen order — drives the
  /// topic grid. Recomputes when [items] changes.
  late final topics = computed<List<HadithTopic>>(() {
    final byTopic = <String, List<Hadith>>{};
    for (final hadith in items.value) {
      (byTopic[hadith.topic] ??= []).add(hadith);
    }
    return [
      for (final entry in byTopic.entries)
        HadithTopic(id: entry.key, items: entry.value),
    ];
  });

  Future<void> load() async {
    final edits = _favoriteEdits;
    final saved = (await _repository.favoriteIds()).valueOrNull;
    if (saved != null && edits == _favoriteEdits) {
      favorites.value = saved;
    }
    final result = await _repository.all();
    if (result.valueOrNull case final value?) {
      items.value = value;
    }
    failed.value = result.valueOrNull == null;
    loaded.value = true;
  }

  /// Adds or removes [id] and persists; false (and the tap taken back)
  /// when it couldn't be saved.
  Future<bool> toggleFavorite(String id) async {
    _favoriteEdits++;
    final next = {...favorites.value};
    final added = next.add(id);
    if (!added) {
      next.remove(id);
    }
    favorites.value = next;
    if ((await _repository.setFavoriteIds(next)).isSuccess) {
      return true;
    }
    // Undo just this id: another toggle may have landed meanwhile.
    final reverted = {...favorites.value};
    added ? reverted.remove(id) : reverted.add(id);
    favorites.value = reverted;
    return false;
  }

  /// Deterministic "hadith of the day": stable for the whole [date], varying
  /// from one day to the next. Returns null when the collection is empty.
  Hadith? ofDay(DateTime date) {
    final list = items.value;
    if (list.isEmpty) {
      return null;
    }
    // Days since epoch, so the rotation doesn't restart every January 1st.
    return list[dailySeed(date) % list.length];
  }
}
