import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/dua.dart';
import '../../domain/repositories/dua_repository.dart';

/// Read-only catalogue state: dua categories, the 99 names and the
/// Prophet's ﷺ names.
final class DuaStore {
  DuaStore(this._repository);

  final DuaRepository _repository;

  late final categories = signal(const <DuaCategory>[]);
  late final asma = signal(const <AsmaName>[]);
  late final rasul = signal(const <AsmaName>[]);

  /// The list for [set].
  List<AsmaName> names(NameSet set) => switch (set) {
    NameSet.allah => asma.value,
    NameSet.rasul => rasul.value,
  };
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  Future<void>? _loading;

  /// Concurrent callers (dua screen, home's dua of the day) share one load.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    final cats = await _repository.categories();
    if (cats.valueOrNull case final value?) {
      categories.value = value;
    }
    final names = await _repository.asmaulHusna();
    if (names.valueOrNull case final value?) {
      asma.value = value;
    }
    final rasulNames = await _repository.rasulNames();
    if (rasulNames.valueOrNull case final value?) {
      rasul.value = value;
    }
    failed.value =
        cats.valueOrNull == null ||
        names.valueOrNull == null ||
        rasulNames.valueOrNull == null;
    loaded.value = true;
  }
}
