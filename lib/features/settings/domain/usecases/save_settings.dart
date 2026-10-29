import '../../../../core/utils/result.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

final class SaveSettings {
  const SaveSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(AppSettings settings) => _repository.save(settings);
}
