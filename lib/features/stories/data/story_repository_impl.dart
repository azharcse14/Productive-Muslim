import '../../../core/utils/result.dart';
import '../domain/entities/story.dart';
import '../domain/repositories/story_repository.dart';
import 'story_asset_data_source.dart';

final class StoryRepositoryImpl implements StoryRepository {
  const StoryRepositoryImpl(this._source);

  final StoryAssetDataSource _source;

  @override
  Future<Result<List<Story>>> stories(StoryKind kind) async {
    try {
      return Result.success(await _source.load(kind));
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('${kind.name} stories load failed', e),
      );
    }
  }
}
