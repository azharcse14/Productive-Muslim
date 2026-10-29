import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:shared_preferences/shared_preferences.dart';

/// App-lock persistence: a salted PIN hash + biometric preference.
/// The raw PIN never touches disk.
///
/// On Android [_prefs] is its own file (app_lock.xml), the one store kept
/// out of cloud backup / device transfer; [legacy] is the shared store older
/// installs kept the lock in, moved over on first use. On iOS [_prefs] is
/// [KeychainPrefs], for the same reason.
final class AppLockDataSource {
  AppLockDataSource(this._prefs, {SharedPreferencesAsync? legacy})
    : _legacy = legacy;

  static const _key = 'app_lock_v1';
  static const _throttleKey = 'app_lock_throttle_v1';

  final SharedPreferencesAsync _prefs;
  final SharedPreferencesAsync? _legacy;
  Future<void>? _moved;

  /// Nothing cached without a legacy store: a future kept across calls
  /// can belong to another zone (tests' runAsync vs fake async) and hang.
  Future<void> _ready() async {
    if (_legacy case final legacy?) {
      await (_moved ??= _moveFromLegacy(legacy));
    }
  }

  Future<void> _moveFromLegacy(SharedPreferencesAsync legacy) async {
    for (final key in [_key, _throttleKey]) {
      final value = await legacy.getString(key);
      if (value == null) {
        continue;
      }
      if (await _prefs.getString(key) == null) {
        await _prefs.setString(key, value);
      }
      await legacy.remove(key);
    }
  }

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<({bool enabled, bool biometric})> read() async {
    await _ready();
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return (enabled: false, biometric: false);
    }
    final map = _decode(raw);
    if (map == null) {
      // Unreadable: fail closed. No PIN verifies, so "Forgot PIN?" (device
      // lock) is the way back in, never a silent unlock.
      return (enabled: true, biometric: false);
    }
    return (
      enabled: map['hash'] is String,
      biometric: map['biometric'] == true,
    );
  }

  /// The stored JSON object, or null when it is corrupt.
  static Map<String, Object?>? _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map ? value.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  /// 16 random bytes from the OS CSPRNG. Older installs used a timestamp
  /// salt; [verify] reads whatever salt is stored, so those still verify.
  static String _newSalt() {
    final random = Random.secure();
    return base64Url.encode([for (var i = 0; i < 16; i++) random.nextInt(256)]);
  }

  Future<void> enable(String pin, {required bool biometric}) async {
    await _ready();
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
    await _ready();
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return false;
    }
    final map = _decode(raw);
    final salt = map?['salt'];
    return map != null &&
        salt is String? &&
        map['hash'] == _hash(pin, salt ?? '');
  }

  Future<void> disable() async {
    await _ready();
    await _prefs.remove(_key);
  }

  /// Wrong-PIN throttle state, persisted so an app restart can't reset it.
  Future<({int failedAttempts, DateTime? lockedUntil})> readThrottle() async {
    await _ready();
    final raw = await _prefs.getString(_throttleKey);
    if (raw == null) {
      return (failedAttempts: 0, lockedUntil: null);
    }
    final map = _decode(raw) ?? const {};
    final until = map['untilMs'];
    final failed = map['failed'];
    final untilMs = until is num ? until.toInt() : null;
    return (
      failedAttempts: failed is num ? failed.toInt() : 0,
      lockedUntil: untilMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(untilMs),
    );
  }

  Future<void> writeThrottle({
    required int failedAttempts,
    required DateTime? lockedUntil,
  }) async {
    await _ready();
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

/// iOS: the lock's three string calls go to the Keychain, this device only
/// (AppDelegate's `LockKeychain`) — UserDefaults rides along in
/// iCloud/Finder backups, and a 4-digit PIN's hash is trivially reversed.
/// Only getString/setString/remove are rerouted; nothing else is used.
final class KeychainPrefs extends SharedPreferencesAsync {
  KeychainPrefs();

  static const _channel = MethodChannel('com.productivemuslim.app/keychain');

  @override
  Future<String?> getString(String key) =>
      _channel.invokeMethod<String>('get', {'key': key});

  @override
  Future<void> setString(String key, String value) =>
      _channel.invokeMethod<void>('set', {'key': key, 'value': value});

  @override
  Future<void> remove(String key) =>
      _channel.invokeMethod<void>('remove', {'key': key});
}
