/// Persisted app-lock record: PIN hash, biometric preference and the
/// wrong-PIN throttle. The raw PIN never leaves [enable]/[verify].
abstract interface class AppLockStorage {
  Future<({bool enabled, bool biometric})> read();
  Future<void> enable(String pin, {required bool biometric});
  Future<bool> verify(String pin);
  Future<void> disable();
  Future<({int failedAttempts, DateTime? lockedUntil})> readThrottle();
  Future<void> writeThrottle({
    required int failedAttempts,
    required DateTime? lockedUntil,
  });
}

/// Biometric seam so the store is testable without the plugin.
abstract interface class BiometricAuth {
  Future<bool> canAuthenticate();
  Future<bool> authenticate(String reason);

  /// Whether the device has its own secure screen lock (PIN/pattern/
  /// password or biometrics) that [authenticateWithDeviceLock] can use.
  Future<bool> canUseDeviceLock();

  /// Authenticates with the device's own screen lock (biometric or device
  /// credential) — the "Forgot PIN?" path.
  Future<bool> authenticateWithDeviceLock(String reason);
}
