import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/repositories/mosque_repository.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/get_mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/save_mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';

final class InMemoryMosqueRepository implements MosqueRepository {
  InMemoryMosqueRepository([this.stored = const MosqueState()]);

  MosqueState stored;
  int saves = 0;

  @override
  Future<Result<MosqueState>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(MosqueState state) async {
    stored = state;
    saves++;
    return const Result.success(null);
  }
}

/// A loaded [MosqueStore] over an in-memory repository.
Future<(MosqueStore, InMemoryMosqueRepository)> makeMosqueStore([
  MosqueState initial = const MosqueState(),
]) async {
  final repo = InMemoryMosqueRepository(initial);
  final store = MosqueStore(GetMosqueState(repo), SaveMosqueState(repo));
  await store.load();
  return (store, repo);
}
