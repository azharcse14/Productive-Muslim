import '../../../core/utils/result.dart';
import '../domain/entities/dua.dart';
import '../domain/repositories/dua_repository.dart';
import 'dua_asset_data_source.dart';

final class DuaRepositoryImpl implements DuaRepository {
  const DuaRepositoryImpl(this._source);

  final DuaAssetDataSource _source;

  @override
  Future<Result<List<DuaCategory>>> categories() async {
    try {
      return Result.success(await _source.loadCategories());
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Dua categories load failed', e),
      );
    }
  }

  @override
  Future<Result<List<AsmaName>>> asmaulHusna() async {
    try {
      return Result.success(await _source.loadAsmaulHusna());
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Asmaul Husna load failed', e),
      );
    }
  }
}
