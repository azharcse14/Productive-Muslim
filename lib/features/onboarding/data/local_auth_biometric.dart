import 'package:local_auth/local_auth.dart';

import '../domain/repositories/app_lock_repository.dart';

/// local_auth implementation — the only class touching the plugin.
final class LocalAuthBiometric implements BiometricAuth {
  LocalAuthBiometric();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> canUseDeviceLock() async {
    try {
      // True when biometrics OR a device credential (PIN/pattern/password)
      // is set up.
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithDeviceLock(String reason) =>
      authenticate(reason);

  /// A cancel or timeout is `false`; anything else (lockout, no sensor,
  /// no enrolled finger) is thrown, so the lock screen can say why.
  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled ||
            LocalAuthExceptionCode.systemCanceled ||
            LocalAuthExceptionCode.timeout ||
            LocalAuthExceptionCode.userRequestedFallback:
          return false;
        default:
          rethrow;
      }
    }
  }
}
