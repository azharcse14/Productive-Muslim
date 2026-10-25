import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

final class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this.stored = const AppSettings()]);

  AppSettings stored;

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

/// A loaded [SettingsStore] over an in-memory repository.
Future<SettingsStore> makeSettingsStore([
  AppSettings initial = const AppSettings(),
]) async {
  final repo = InMemorySettingsRepository(initial);
  final store = SettingsStore(GetSettings(repo), SaveSettings(repo));
  await store.load();
  return store;
}
