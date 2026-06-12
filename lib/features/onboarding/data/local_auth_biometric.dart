import 'package:local_auth/local_auth.dart';

import '../presentation/state/app_lock_store.dart';

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
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on Object {
      return false;
    }
  }
}
