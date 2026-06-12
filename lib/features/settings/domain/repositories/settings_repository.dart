import '../../../../core/utils/result.dart';
import '../entities/app_settings.dart';

/// Persisted app settings. Backed by shared_preferences in the data layer
/// (decided once — see docs/DEPENDENCIES.md "Decisions").
abstract interface class SettingsRepository {
  /// Returns defaults on first run.
  Future<Result<AppSettings>> load();

  Future<Result<void>> save(AppSettings settings);
}
