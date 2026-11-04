import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/lineage.dart';
import '../../domain/entities/prophet.dart';
import '../../domain/repositories/prophet_repository.dart';

/// Read-only state: the bundled prophets and their timeline-tree rows.
final class ProphetsStore {
  ProphetsStore(this._repository);

  final ProphetRepository _repository;

  late final prophets = signal(const <Prophet>[]);
  late final rows = computed(() => layoutLineage(prophets.value));
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  Future<void> load() async {
    final result = await _repository.prophets();
    if (result.valueOrNull case final value?) {
      prophets.value = value;
    }
    failed.value = result.valueOrNull == null;
    loaded.value = true;
  }
}
