import '../../../../core/utils/result.dart';
import '../../domain/entities/mosque_state.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../datasources/mosque_local_data_source.dart';

final class MosqueRepositoryImpl implements MosqueRepository {
  const MosqueRepositoryImpl(this._local);

  final MosqueLocalDataSource _local;

  @override
  Future<Result<MosqueState>> load() async {
    try {
      return Result.success(await _local.read());
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Failed to load mosque state', e),
      );
    }
  }

  @override
  Future<Result<void>> save(MosqueState state) async {
    try {
      await _local.write(state);
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Failed to save mosque state', e),
      );
    }
  }
}
