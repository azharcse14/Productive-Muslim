import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/ruqyah.dart';
import '../../domain/repositories/ruqyah_repository.dart';

/// Read-only catalogue state: the bundled ruqyah categories.
final class RuqyahStore {
  RuqyahStore(this._repository);

  final RuqyahRepository _repository;

  late final categories = signal(const <RuqyahCategory>[]);
  late final loaded = signal(false);

  Future<void> load() async {
    final cats = await _repository.categories();
    if (cats.valueOrNull case final value?) {
      categories.value = value;
    }
    loaded.value = true;
  }
}
