import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/dua.dart';
import '../../domain/repositories/dua_repository.dart';

/// Read-only catalogue state: dua categories + the 99 names.
final class DuaStore {
  DuaStore(this._repository);

  final DuaRepository _repository;

  late final categories = signal(const <DuaCategory>[]);
  late final asma = signal(const <AsmaName>[]);
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  Future<void> load() async {
    final cats = await _repository.categories();
    if (cats.valueOrNull case final value?) {
      categories.value = value;
    }
    final names = await _repository.asmaulHusna();
    if (names.valueOrNull case final value?) {
      asma.value = value;
    }
    failed.value = cats.valueOrNull == null || names.valueOrNull == null;
    loaded.value = true;
  }
}
