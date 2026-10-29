import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/ruqyah.dart';
import '../../domain/repositories/ruqyah_repository.dart';

/// Read-only catalogue state: the bundled ruqyah categories.
final class RuqyahStore {
  RuqyahStore(this._repository);

  /// get_it instance name of the store backing the Tibb an-Nabawi screen.
  static const tibbNabawi = 'tibbNabawi';

  final RuqyahRepository _repository;

  late final categories = signal(const <RuqyahCategory>[]);
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  Future<void> load() async {
    final cats = await _repository.categories();
    if (cats.valueOrNull case final value?) {
      categories.value = value;
    }
    failed.value = cats.valueOrNull == null;
    loaded.value = true;
  }
}
