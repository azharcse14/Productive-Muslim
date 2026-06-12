import '../../../../core/utils/result.dart';
import '../entities/mosque_state.dart';
import '../repositories/mosque_repository.dart';

final class GetMosqueState {
  const GetMosqueState(this._repository);

  final MosqueRepository _repository;

  Future<Result<MosqueState>> call() => _repository.load();
}
