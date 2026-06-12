import '../../../../core/utils/result.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<Result<AppSettings>> load() async {
    try {
      return Result.success(await _local.read());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load settings', e));
    }
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    try {
      await _local.write(settings);
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to save settings', e));
    }
  }
}
