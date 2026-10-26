import 'dart:math' as math;

import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../data/app_lock_data_source.dart';

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

/// Outcome of the "Forgot PIN?" device-lock check.
enum PinResetAuth { verified, failed, noDeviceLock }

/// App-lock state: whether the app is locked right now and the
/// enable/verify flows. The router redirect watches [locked].
///
/// Re-locks after the app has been in the background longer than
/// [AppConfig.appLockGracePeriod]; wrong PINs are throttled with a
/// persisted, growing cooldown.
final class AppLockStore {
  AppLockStore(
    this._source,
    this._biometric, {
    DateTime Function()? now,
    Duration Function()? elapsed,
  })  : _now = now ?? DateTime.now,
        _elapsed = elapsed ?? (now == null ? _stopwatch() : _since(now));

  final AppLockDataSource _source;
  final BiometricAuth _biometric;
  final DateTime Function() _now;

  /// Monotonic time since construction — immune to wall-clock changes.
  /// Tests that inject only [now] get it derived from that clock.
  final Duration Function() _elapsed;

  static Duration Function() _stopwatch() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  static Duration Function() _since(DateTime Function() now) {
    final start = now();
    return () => now().difference(start);
  }

  /// Wrong attempts allowed before the first cooldown.
  static const freeAttempts = 5;
  static const _baseCooldown = Duration(seconds: 30);

  /// Cooldown doubling stops here (30s × 2^7 ≈ 64 min).
  static const _maxDoublings = 7;

  late final enabled = signal(false);
  late final biometricEnabled = signal(false);

  /// True while the gate must show (enabled and not yet unlocked).
  late final locked = signal(false);

  /// PIN entry is blocked until this instant (null = not throttled).
  late final lockedUntil = signal<DateTime?>(null);

  var _failedAttempts = 0;

  /// Current cooldown: its length and start on both clocks. Time served is
  /// the larger of the two — the monotonic clock pauses while the device
  /// sleeps, and a clock set backwards must not stretch the wait.
  /// ponytail: a clock set forward skips the current wait (as killing the
  /// app does); escalation still holds. Boot-time clock if that matters.
  Duration? _cooldownSpan;
  Duration _cooldownStartMono = Duration.zero;
  DateTime? _cooldownStartWall;
  DateTime? _backgroundedAt;
  AppLifecycleListener? _lifecycle;

  /// True while an OS auth prompt is up: biometric/device-credential UIs
  /// push the app to inactive/paused on some platforms, which must not
  /// count as leaving the app (or every prompt would re-lock).
  var _authInProgress = false;

  /// Cooldown after [failures] consecutive wrong PINs: none for the first
  /// [freeAttempts], then 30s, 60s, 120s… capped at ~64 min.
  static Duration? cooldownFor(int failures) {
    if (failures < freeAttempts) {
      return null;
    }
    final doublings = math.min(failures - freeAttempts, _maxDoublings);
    return _baseCooldown * (1 << doublings);
  }

  /// Time left on the PIN cooldown, or null when entry is allowed.
  Duration? cooldownRemaining() {
    final span = _cooldownSpan;
    final startWall = _cooldownStartWall;
    if (lockedUntil.value == null || span == null || startWall == null) {
      return null;
    }
    final mono = _elapsed() - _cooldownStartMono;
    final wall = _now().difference(startWall);
    final left = span - (wall > mono ? wall : mono);
    return left > Duration.zero ? left : null;
  }

  /// Starts (or clears) a cooldown of [span] on both clocks.
  void _startCooldown(Duration? span) {
    _cooldownSpan = span;
    _cooldownStartMono = _elapsed();
    _cooldownStartWall = _now();
    lockedUntil.value = span == null ? null : _now().add(span);
  }

  Future<void> load() async {
    final state = await _source.read();
    enabled.value = state.enabled;
    biometricEnabled.value = state.biometric;
    locked.value = state.enabled;
    final throttle = await _source.readThrottle();
    _failedAttempts = throttle.failedAttempts;
    // Resume the persisted cooldown, clamped to the longest this attempt
    // count can earn — a clock set backwards can't stretch it.
    final until = throttle.lockedUntil;
    final cap = cooldownFor(_failedAttempts);
    if (until == null || cap == null) {
      _startCooldown(null);
    } else {
      final left = until.difference(_now());
      _startCooldown(
        left <= Duration.zero ? null : (left > cap ? cap : left),
      );
    }
  }

  /// Starts watching app lifecycle for background re-locking. Call once.
  void watchLifecycle() {
    _lifecycle ??= AppLifecycleListener(onStateChange: onLifecycleChanged);
  }

  /// Lifecycle hook (public for tests): remembers when the app left the
  /// foreground and re-locks on resume once the grace period has passed.
  void onLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (enabled.value && !_authInProgress) {
          _backgroundedAt ??= _now();
        }
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            enabled.value &&
            !_authInProgress &&
            _now().difference(since) >= AppConfig.appLockGracePeriod) {
          locked.value = true;
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Whether biometric unlock is available to offer at PIN setup.
  Future<bool> canUseBiometric() => _biometric.canAuthenticate();

  Future<void> enable(String pin, {required bool biometric}) async {
    await _source.enable(pin, biometric: biometric);
    await _resetThrottle();
    enabled.value = true;
    biometricEnabled.value = biometric;
  }

  Future<void> disable() async {
    await _source.disable();
    await _resetThrottle();
    enabled.value = false;
    biometricEnabled.value = false;
    locked.value = false;
  }

  /// Verifies [pin]. Always false while throttled ([lockedUntil] in the
  /// future) — the PIN is not even checked.
  Future<bool> unlockWithPin(String pin) async {
    if (cooldownRemaining() != null) {
      return false;
    }
    final ok = await _source.verify(pin);
    if (ok) {
      await _resetThrottle();
      locked.value = false;
      return true;
    }
    _failedAttempts++;
    _startCooldown(cooldownFor(_failedAttempts));
    await _source.writeThrottle(
      failedAttempts: _failedAttempts,
      lockedUntil: lockedUntil.value,
    );
    return false;
  }

  /// Attempts biometric unlock (no-op false when unavailable/disabled).
  Future<bool> unlockWithBiometric(String reason) async {
    if (!biometricEnabled.value || !await _biometric.canAuthenticate()) {
      return false;
    }
    final ok = await _duringAuth(() => _biometric.authenticate(reason));
    if (ok) {
      await _resetThrottle();
      locked.value = false;
    }
    return ok;
  }

  /// "Forgot PIN?": proves device ownership via the device's own screen
  /// lock. On [PinResetAuth.verified] the caller collects a new PIN and
  /// calls [resetPin].
  Future<PinResetAuth> authenticateForPinReset(String reason) async {
    if (!await _biometric.canUseDeviceLock()) {
      return PinResetAuth.noDeviceLock;
    }
    final ok = await _duringAuth(
      () => _biometric.authenticateWithDeviceLock(reason),
    );
    return ok ? PinResetAuth.verified : PinResetAuth.failed;
  }

  /// Replaces the PIN after [authenticateForPinReset] and unlocks.
  Future<void> resetPin(String pin) async {
    await enable(pin, biometric: biometricEnabled.value);
    locked.value = false;
  }

  Future<bool> _duringAuth(Future<bool> Function() prompt) async {
    _authInProgress = true;
    try {
      return await prompt();
    } finally {
      _authInProgress = false;
      // Any pause/resume during the prompt belongs to the prompt.
      _backgroundedAt = null;
    }
  }

  Future<void> _resetThrottle() async {
    if (_failedAttempts == 0 && lockedUntil.value == null) {
      return;
    }
    _failedAttempts = 0;
    _startCooldown(null);
    await _source.writeThrottle(failedAttempts: 0, lockedUntil: null);
  }

  void dispose() => _lifecycle?.dispose();
}
