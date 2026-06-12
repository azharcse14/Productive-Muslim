import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-lock persistence: a salted PIN hash + biometric preference.
/// The raw PIN never touches disk.
final class AppLockDataSource {
  const AppLockDataSource(this._prefs);

  static const _key = 'app_lock_v1';

  final SharedPreferencesAsync _prefs;

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<({bool enabled, bool biometric})> read() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return (enabled: false, biometric: false);
    }
    final map = (jsonDecode(raw) as Map).cast<String, Object?>();
    return (
      enabled: map['hash'] is String,
      biometric: map['biometric'] as bool? ?? false,
    );
  }

  Future<void> enable(String pin, {required bool biometric}) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await _prefs.setString(
      _key,
      jsonEncode({
        'salt': salt,
        'hash': _hash(pin, salt),
        'biometric': biometric,
      }),
    );
  }

  Future<bool> verify(String pin) async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return false;
    }
    final map = (jsonDecode(raw) as Map).cast<String, Object?>();
    final salt = map['salt'] as String? ?? '';
    return map['hash'] == _hash(pin, salt);
  }

  Future<void> disable() => _prefs.remove(_key);
}
