import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/ruqyah/domain/entities/ruqyah.dart';
import 'package:productive_muslim/features/ruqyah/domain/repositories/ruqyah_repository.dart';
import 'package:productive_muslim/features/ruqyah/presentation/state/ruqyah_store.dart';

/// Succeeds on the first call, fails on any later one.
final class _FailsAfterFirst implements RuqyahRepository {
  int calls = 0;

  @override
  Future<Result<List<RuqyahCategory>>> categories() async {
    calls++;
    await Future<void>.delayed(Duration.zero);
    return calls == 1
        ? const Result.success([
            RuqyahCategory(id: 'anxiety_grief', icon: 'heart', items: []),
          ])
        : const Result.failure(UnexpectedFailure('boom'));
  }
}

void main() {
  test('concurrent loads share one read, so a late failure cannot land '
      'over loaded data', () async {
    final repo = _FailsAfterFirst();
    final store = RuqyahStore(repo);

    await Future.wait([store.load(), store.load()]);

    expect(repo.calls, 1);
    expect(store.failed.value, isFalse);
    expect(store.categories.value, hasLength(1));
  });
}
