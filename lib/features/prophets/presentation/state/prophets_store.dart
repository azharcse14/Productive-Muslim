import 'package:signals_flutter/signals_flutter.dart';

import '../../../stories/domain/entities/story.dart';
import '../../../stories/domain/repositories/story_repository.dart';
import '../../domain/entities/lineage.dart';
import '../../domain/entities/prophet.dart';
import '../../domain/repositories/prophet_repository.dart';

/// Read-only state: the bundled prophets and their timeline-tree rows.
final class ProphetsStore {
  ProphetsStore(this._repository, this._stories);

  final ProphetRepository _repository;
  final StoryRepository _stories;

  late final prophets = signal(const <Prophet>[]);
  late final rows = computed(() => layoutLineage(prophets.value));
  late final loaded = signal(false);

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  /// Quran stories by id, for a prophet's `storyIds`. Empty when they failed
  /// to load — the detail page then shows no story buttons.
  late final quranStories = signal(const <String, Story>{});

  Future<void> load() async {
    final (result, stories) = (
      await _repository.prophets(),
      await _stories.stories(StoryKind.quran),
    );
    if (result.valueOrNull case final value?) {
      prophets.value = value;
    }
    if (stories.valueOrNull case final value?) {
      quranStories.value = {for (final s in value) s.id: s};
    }
    failed.value = result.valueOrNull == null;
    loaded.value = true;
  }
}
