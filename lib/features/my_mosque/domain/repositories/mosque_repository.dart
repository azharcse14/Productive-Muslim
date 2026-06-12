import '../../../../core/utils/result.dart';
import '../entities/mosque_state.dart';

/// Persisted mosque profiles. Backed by shared_preferences in the data
/// layer, mirroring SettingsRepository.
abstract interface class MosqueRepository {
  /// Returns an empty [MosqueState] on first run.
  Future<Result<MosqueState>> load();

  Future<Result<void>> save(MosqueState state);
}
