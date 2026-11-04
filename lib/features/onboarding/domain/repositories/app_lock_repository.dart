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

  /// What the lock guards; [LockScope.app] when never set. [disable]
  /// forgets it.
  Future<LockScope> readScope();
  Future<void> writeScope(LockScope scope);
}

/// What the PIN lock guards: the whole app, or only the Muhasaba section.
enum LockScope {
  app('app'),
  muhasaba('muhasaba');

  const LockScope(this.code);

  /// Stable persisted code.
  final String code;

  /// Unknown or missing codes (a newer version's scope) read as [app]:
  /// fail closed, locking more rather than less.
  static LockScope fromCode(Object? code) =>
      values.where((s) => s.code == code).firstOrNull ?? app;
}

/// Read side of the Muhasaba section lock, for screens outside Muhasaba
/// that show its data (Home's summary card). Signal-backed: reading it in
/// a reactive builder rebuilds that builder when it changes.
abstract interface class SectionLockStatus {
  /// Whether Muhasaba data must stay hidden right now.
  bool get muhasabaLocked;
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

  /// False on a cancel or a rejected try; throws when biometrics can't be
  /// used right now (lockout, sensor gone).
  Future<bool> authenticate(String reason);

  /// Whether the device has its own secure screen lock (PIN/pattern/
  /// password or biometrics) that [authenticateWithDeviceLock] can use.
  Future<bool> canUseDeviceLock();

  /// Authenticates with the device's own screen lock (biometric or device
  /// credential) — the "Forgot PIN?" path. Like [authenticate]: false on
  /// a cancel or a rejected try, throws when it can't be used (lockout).
  Future<bool> authenticateWithDeviceLock(String reason);
}
