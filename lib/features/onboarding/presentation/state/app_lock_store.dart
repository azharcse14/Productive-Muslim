import 'package:signals_flutter/signals_flutter.dart';

import '../../data/app_lock_data_source.dart';

/// Biometric seam so the store is testable without the plugin.
abstract interface class BiometricAuth {
  Future<bool> canAuthenticate();
  Future<bool> authenticate(String reason);
}

/// App-lock state: whether the app is locked right now and the
/// enable/verify flows. The router redirect watches [locked].
final class AppLockStore {
  AppLockStore(this._source, this._biometric);

  final AppLockDataSource _source;
  final BiometricAuth _biometric;

  late final enabled = signal(false);
  late final biometricEnabled = signal(false);

  /// True while the gate must show (enabled and not yet unlocked).
  late final locked = signal(false);

  Future<void> load() async {
    final state = await _source.read();
    enabled.value = state.enabled;
    biometricEnabled.value = state.biometric;
    locked.value = state.enabled;
  }

  Future<void> enable(String pin, {required bool biometric}) async {
    await _source.enable(pin, biometric: biometric);
    enabled.value = true;
    biometricEnabled.value = biometric;
  }

  Future<void> disable() async {
    await _source.disable();
    enabled.value = false;
    biometricEnabled.value = false;
    locked.value = false;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await _source.verify(pin);
    if (ok) {
      locked.value = false;
    }
    return ok;
  }

  /// Attempts biometric unlock (no-op false when unavailable/disabled).
  Future<bool> unlockWithBiometric(String reason) async {
    if (!biometricEnabled.value || !await _biometric.canAuthenticate()) {
      return false;
    }
    final ok = await _biometric.authenticate(reason);
    if (ok) {
      locked.value = false;
    }
    return ok;
  }
}
