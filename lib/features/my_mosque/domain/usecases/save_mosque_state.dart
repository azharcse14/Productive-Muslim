import '../../../../core/utils/result.dart';
import '../entities/mosque_state.dart';
import '../repositories/mosque_repository.dart';

final class SaveMosqueState {
  const SaveMosqueState(this._repository);

  final MosqueRepository _repository;

  Future<Result<void>> call(MosqueState state) => _repository.save(state);
}
