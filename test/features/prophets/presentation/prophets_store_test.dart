import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prophets/domain/entities/prophet.dart';
import 'package:productive_muslim/features/prophets/domain/repositories/prophet_repository.dart';
import 'package:productive_muslim/features/prophets/presentation/state/prophets_store.dart';
import 'package:productive_muslim/features/stories/domain/entities/story.dart';
import 'package:productive_muslim/features/stories/domain/repositories/story_repository.dart';

const _ibrahim = Prophet(
  id: 'ibrahim',
  order: 1,
  nameAr: 'إبراهيم',
  nameEn: 'Ibrahim',
  nameBn: 'ইবরাহিম',
);

/// Succeeds on the first call, fails on any later one.
final class _FailsAfterFirst implements ProphetRepository {
  int calls = 0;

  @override
  Future<Result<List<Prophet>>> prophets() async {
    calls++;
    await Future<void>.delayed(Duration.zero);
    return calls == 1
        ? const Result.success([_ibrahim])
        : const Result.failure(UnexpectedFailure('boom'));
  }

  @override
  Future<Result<List<Prophet>>> lineage() async =>
      const Result.success([_ibrahim]);
}

final class _NoStories implements StoryRepository {
  @override
  Future<Result<List<Story>>> stories(StoryKind kind) async =>
      const Result.success([]);
}

void main() {
  test('concurrent loads share one read, so a late failure cannot land '
      'over loaded data', () async {
    final repo = _FailsAfterFirst();
    final store = ProphetsStore(repo, _NoStories());

    await Future.wait([store.load(), store.load()]);

    expect(repo.calls, 1);
    expect(store.failed.value, isFalse);
    expect(store.prophets.value, [_ibrahim]);
  });
}
