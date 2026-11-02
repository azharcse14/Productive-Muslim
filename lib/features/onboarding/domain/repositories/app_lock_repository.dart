/// Persisted app-lock record: PIN hash, biometric preference and the
/// wrong-PIN throttle. The raw PIN never leaves [enable]/[verify].
abstract interface class AppLockStorage {
  Future<({bool enabled, bool biometric})> read();
  Future<void> enable(String pin, {required bool biometric});
  Future<bool> verify(String pin);
  Future<void> disable();
  Future<({int failedAttempts, PinCooldown? cooldown})> readThrottle();
  Future<void> writeThrottle({
    required int failedAttempts,
    required PinCooldown? cooldown,
  });
}

/// A running wrong-PIN cooldown on the [BootClock]: started at
/// `startedAtBoot` (null = unknown, e.g. a pre-boot-clock record) with
/// `left` still to serve from then. Wall time is never trusted for it.
typedef PinCooldown = ({Duration? startedAtBoot, Duration left});

/// Keeps the app's window out of screenshots and the recents thumbnail
/// while the lock is on (Android FLAG_SECURE).
abstract interface class SecureScreen {
  /// Best-effort: never throws.
  Future<void> setSecure({required bool on});
}

/// Time since the device booted, counting deep sleep, unaffected by wall
/// clock changes. Restarts near zero after a reboot.
abstract interface class BootClock {
  Future<Duration> sinceBoot();
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
