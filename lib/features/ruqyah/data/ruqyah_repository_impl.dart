import '../../../core/utils/result.dart';
import '../domain/entities/ruqyah.dart';
import '../domain/repositories/ruqyah_repository.dart';
import 'ruqyah_asset_data_source.dart';

final class RuqyahRepositoryImpl implements RuqyahRepository {
  const RuqyahRepositoryImpl(this._source);

  final RuqyahAssetDataSource _source;

  @override
  Future<Result<List<RuqyahCategory>>> categories() async {
    try {
      return Result.success(await _source.loadCategories());
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Ruqyah categories load failed', e),
      );
    }
  }
}
