import 'package:signals_flutter/signals_flutter.dart';

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
    final result = await _repository.all();
    if (result.valueOrNull case final value?) {
      items.value = value;
    }
    failed.value = result.valueOrNull == null;
    loaded.value = true;
  }

  /// Deterministic "hadith of the day": stable for the whole [date], varying
  /// from one day to the next. Returns null when the collection is empty.
  Hadith? ofDay(DateTime date) {
    final list = items.value;
    if (list.isEmpty) {
      return null;
    }
    // UTC on both sides: a DST shift would otherwise drop a day (23h).
    final dayOfYear = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(date.year))
        .inDays;
    return list[dayOfYear % list.length];
  }
}
