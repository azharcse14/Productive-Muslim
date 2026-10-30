import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/json_prefs.dart';
import '../../domain/entities/app_settings.dart';
import '../models/app_settings_model.dart';

/// shared_preferences-backed storage. One JSON blob keeps the settings
/// atomic — partial writes can't tear the config.
final class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._prefs);

  static const _key = 'app_settings_v1';

  /// Last blob that failed to parse, kept verbatim so the save that
  /// follows re-onboarding (which overwrites [_key]) can't destroy it.
  static const unreadableKey = 'app_settings_v1_unreadable';

  final SharedPreferencesAsync _prefs;

  Future<AppSettings> read() async {
    final map = await readJsonObject(
      _prefs,
      _key,
      unreadableKey: unreadableKey,
    );
    return map == null ? const AppSettings() : AppSettingsModel.fromMap(map);
  }

  Future<void> write(AppSettings settings) =>
      _prefs.setString(_key, jsonEncode(AppSettingsModel.toMap(settings)));
}
