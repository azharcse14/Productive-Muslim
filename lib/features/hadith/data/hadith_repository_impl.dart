import '../../../core/utils/result.dart';
import '../domain/entities/hadith.dart';
import '../domain/repositories/hadith_repository.dart';
import 'hadith_asset_data_source.dart';

final class HadithRepositoryImpl implements HadithRepository {
  const HadithRepositoryImpl(this._source);

  final HadithAssetDataSource _source;

  @override
  Future<Result<List<Hadith>>> all() async {
    try {
      return Result.success(await _source.loadAll());
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Hadith load failed', e),
      );
    }
  }
}
