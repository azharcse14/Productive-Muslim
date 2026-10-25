import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-lock persistence: a salted PIN hash + biometric preference.
/// The raw PIN never touches disk.
final class AppLockDataSource {
  const AppLockDataSource(this._prefs);

  static const _key = 'app_lock_v1';
  static const _throttleKey = 'app_lock_throttle_v1';

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

  /// 16 random bytes from the OS CSPRNG. Older installs used a timestamp
  /// salt; [verify] reads whatever salt is stored, so those still verify.
  static String _newSalt() {
    final random = Random.secure();
    return base64Url.encode([for (var i = 0; i < 16; i++) random.nextInt(256)]);
  }

  Future<void> enable(String pin, {required bool biometric}) async {
    final salt = _newSalt();
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

  /// Wrong-PIN throttle state, persisted so an app restart can't reset it.
  Future<({int failedAttempts, DateTime? lockedUntil})> readThrottle() async {
    final raw = await _prefs.getString(_throttleKey);
    if (raw == null) {
      return (failedAttempts: 0, lockedUntil: null);
    }
    final map = (jsonDecode(raw) as Map).cast<String, Object?>();
    final untilMs = (map['untilMs'] as num?)?.toInt();
    return (
      failedAttempts: (map['failed'] as num?)?.toInt() ?? 0,
      lockedUntil: untilMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(untilMs),
    );
  }

  Future<void> writeThrottle({
    required int failedAttempts,
    required DateTime? lockedUntil,
  }) async {
    if (failedAttempts == 0 && lockedUntil == null) {
      await _prefs.remove(_throttleKey);
      return;
    }
    await _prefs.setString(
      _throttleKey,
      jsonEncode({
        'failed': failedAttempts,
        'untilMs': lockedUntil?.millisecondsSinceEpoch,
      }),
    );
  }
}
