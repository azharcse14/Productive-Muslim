import 'package:local_auth/local_auth.dart';

import '../domain/repositories/app_lock_repository.dart';

/// local_auth implementation — the only class touching the plugin.
final class LocalAuthBiometric implements BiometricAuth {
  LocalAuthBiometric();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics;
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
  Future<bool> authenticateWithDeviceLock(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on Object {
      return false;
    }
  }
}
