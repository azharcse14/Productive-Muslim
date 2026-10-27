import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('SettingsLocalDataSource', () {
    test('returns defaults when nothing is stored', () async {
      final source = SettingsLocalDataSource(SharedPreferencesAsync());
      expect(await source.read(), const AppSettings());
    });

    test('write → read round-trips', () async {
      final source = SettingsLocalDataSource(SharedPreferencesAsync());
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        localeCode: 'bn',
        setupComplete: true,
      );
      await source.write(settings);
      expect(await source.read(), settings);
    });

    test('corrupt payload falls back to defaults and is quarantined', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('app_settings_v1', '{"weird": ');
      final source = SettingsLocalDataSource(prefs);
      expect(await source.read(), const AppSettings());
      await source.write(const AppSettings(setupComplete: true));
      expect(
        await prefs.getString(SettingsLocalDataSource.unreadableKey),
        '{"weird": ',
      );
    });

    test('non-object payload is quarantined too', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('app_settings_v1', '[1]');
      final source = SettingsLocalDataSource(prefs);
      expect(await source.read(), const AppSettings());
      expect(
        await prefs.getString(SettingsLocalDataSource.unreadableKey),
        '[1]',
      );
    });
  });
}
