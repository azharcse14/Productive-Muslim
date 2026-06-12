import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../models/app_settings_model.dart';

/// shared_preferences-backed storage. One JSON blob keeps the settings
/// atomic — partial writes can't tear the config.
final class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._prefs);

  static const _key = 'app_settings_v1';

  final SharedPreferencesAsync _prefs;

  Future<AppSettings> read() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return const AppSettings();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const AppSettings();
    }
    return AppSettingsModel.fromMap(decoded.cast<String, Object?>());
  }

  Future<void> write(AppSettings settings) =>
      _prefs.setString(_key, jsonEncode(AppSettingsModel.toMap(settings)));
}
