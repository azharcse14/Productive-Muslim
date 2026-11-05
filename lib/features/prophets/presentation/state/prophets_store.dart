import 'package:signals_flutter/signals_flutter.dart';

import '../../../stories/domain/entities/story.dart';
import '../../../stories/domain/repositories/story_repository.dart';
import '../../domain/entities/lineage.dart';
import '../../domain/entities/prophet.dart';
import '../../domain/repositories/prophet_repository.dart';

/// Read-only state: the bundled prophets, the full lineage and their
/// timeline-tree rows.
final class ProphetsStore {
  ProphetsStore(this._repository, this._stories);

  final ProphetRepository _repository;
  final StoryRepository _stories;

  late final prophets = signal(const <Prophet>[]);
  late final rows = computed(() => layoutLineage(prophets.value));
  late final loaded = signal(false);

  /// Everyone in the chart lineage; prophets keep their own ids.
  late final lineage = signal(const <Prophet>[]);
  late final lineageRows = computed(() => layoutLineage(lineage.value));
  late final prophetIds = computed(
    () => {for (final p in prophets.value) p.id},
  );

  /// The last load failed; the screen offers a retry.
  late final failed = signal(false);

  /// The last lineage load failed; that tab offers a retry.
  late final lineageFailed = signal(false);

  /// Quran stories by id, for a prophet's `storyIds`. Empty when they failed
  /// to load — the detail page then shows no story buttons.
  late final quranStories = signal(const <String, Story>{});

  Future<void> load() async {
    final (result, stories, lineage) = (
      await _repository.prophets(),
      await _stories.stories(StoryKind.quran),
      await _repository.lineage(),
    );
    if (result.valueOrNull case final value?) {
      prophets.value = value;
    }
    if (lineage.valueOrNull case final value?) {
      this.lineage.value = value;
    }
    if (stories.valueOrNull case final value?) {
      quranStories.value = {for (final s in value) s.id: s};
    }
    failed.value = result.valueOrNull == null;
    lineageFailed.value = lineage.valueOrNull == null;
    loaded.value = true;
  }
}
