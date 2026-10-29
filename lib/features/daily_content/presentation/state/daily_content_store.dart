import 'package:signals_flutter/signals_flutter.dart';

import '../../../dua_tasbih/domain/entities/dua.dart';
import '../../../dua_tasbih/presentation/state/dua_store.dart';
import '../../domain/usecases/pick_daily_content.dart';

/// Resolves the "dua of the day" deterministically from the bundled dua
/// collection via [pickDailyContent]. Pass the day's date in; the result is
/// stable for the whole calendar day (guide §4: derive, don't duplicate —
/// the pick is computed off the store's loaded list).
///
/// Intentionally dua-only: the hadith "of the day" already lives on the home
/// via [HadithStore.ofDay], so this stays decoupled from the hadith feature.
final class DailyContentStore {
  DailyContentStore(this._dua);

  final DuaStore _dua;

  /// The date to pick for; the home sets this from its `dateKey` so the pick
  /// flips at local midnight along with the rest of the home.
  final date = signal<DateTime>(DateTime(1970));

  /// Flattened dua pool across all categories, first-seen order.
  late final _allDuas = computed<List<Dua>>(
    () => [for (final category in _dua.categories.value) ...category.duas],
  );

  late final _selection = computed<DailyContentSelection>(
    () => pickDailyContent(
      date: date.value,
      ayahPoolSize: 0,
      hadithPoolSize: 0,
      duaPoolSize: _allDuas.value.length,
    ),
  );

  late final duaOfDay = computed<Dua?>(() {
    final i = _selection.value.duaIndex;
    final list = _allDuas.value;
    return (i == null || i >= list.length) ? null : list[i];
  });

  /// Ensures the dua collection is loaded (retrying a failed load), then
  /// points the store at [date].
  Future<void> load(DateTime forDate) async {
    if (!_dua.loaded.value || _dua.failed.value) {
      await _dua.load();
    }
    date.value = DateTime(forDate.year, forDate.month, forDate.day);
  }
}
