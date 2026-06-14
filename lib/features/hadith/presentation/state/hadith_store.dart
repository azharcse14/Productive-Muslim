import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';

/// Read-only state for the bundled hadith collection.
final class HadithStore {
  HadithStore(this._repository);

  final HadithRepository _repository;

  late final items = signal(const <Hadith>[]);
  late final loaded = signal(false);

  Future<void> load() async {
    final result = await _repository.all();
    if (result.valueOrNull case final value?) {
      items.value = value;
    }
    loaded.value = true;
  }

  /// Deterministic "hadith of the day": stable for the whole [date], varying
  /// from one day to the next. Returns null when the collection is empty.
  Hadith? ofDay(DateTime date) {
    final list = items.value;
    if (list.isEmpty) {
      return null;
    }
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return list[dayOfYear % list.length];
  }
}
