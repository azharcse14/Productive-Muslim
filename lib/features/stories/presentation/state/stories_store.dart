import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';

/// Read-only catalogue state: the bundled stories, per kind.
final class StoriesStore {
  StoriesStore(this._repository);

  final StoryRepository _repository;

  /// Loaded stories by kind; a missing key means "not loaded yet".
  late final stories = signal(const <StoryKind, List<Story>>{});

  /// Kinds whose last load failed; the screen offers a retry.
  late final failed = signal(const <StoryKind>{});

  Future<void> load(StoryKind kind) async {
    final result = await _repository.stories(kind);
    switch (result.valueOrNull) {
      case final value?:
        stories.value = {...stories.value, kind: value};
        failed.value = {...failed.value}..remove(kind);
      case null:
        failed.value = {...failed.value, kind};
    }
  }
}
