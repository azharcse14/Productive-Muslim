import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../domain/repositories/app_lock_repository.dart';

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
  }) : _now = now ?? DateTime.now,
       _elapsed = elapsed ?? (now == null ? _stopwatch() : _since(now));

  final AppLockStorage _source;
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

  /// True between a verified "Forgot PIN?" device-lock check and
  /// [resetPin]. Leaving the app revokes it, so whoever opens it next
  /// can't pick up a half-finished reset.
  late final pinResetAuthorized = signal(false);

  /// True while the app is not in the foreground with the lock enabled:
  /// the root covers its UI so the OS app switcher snapshot (and the
  /// first resumed frame, before the gate redirect) shows nothing.
  late final obscured = signal(false);

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
  Duration _backgroundedAtMono = Duration.zero;
  AppLifecycleListener? _lifecycle;

  /// True while an OS auth prompt is up: biometric/device-credential UIs
  /// push the app to inactive/paused on some platforms, which must not
  /// count as leaving the app (or every prompt would re-lock).
  var _authInProgress = false;

  /// The app came back from longer than the grace period mid-prompt; a
  /// failed prompt re-locks then (a passed one proves the user is here).
  var _awayDuringAuth = false;

  /// True while a PIN is being checked: a second attempt is refused, or
  /// both would pass the cooldown check before either counted.
  var _pinInFlight = false;

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
    final ({int failedAttempts, DateTime? lockedUntil}) throttle;
    try {
      throttle = await _source.readThrottle();
    } on Object {
      // The lock state read fine; an unreadable cooldown must not lock out
      // a user who has no PIN. Start the count fresh.
      _failedAttempts = 0;
      _startCooldown(null);
      return;
    }
    _failedAttempts = throttle.failedAttempts;
    // Resume the persisted cooldown, clamped to the longest this attempt
    // count can earn — a clock set backwards can't stretch it.
    final until = throttle.lockedUntil;
    final cap = cooldownFor(_failedAttempts);
    if (until == null || cap == null) {
      _startCooldown(null);
    } else {
      final left = until.difference(_now());
      _startCooldown(left <= Duration.zero ? null : (left > cap ? cap : left));
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
        if (enabled.value && _backgroundedAt == null) {
          _backgroundedAt = _now();
          _backgroundedAtMono = _elapsed();
        }
        if (enabled.value && !_authInProgress) {
          pinResetAuthorized.value = false;
          obscured.value = true;
        }
      case AppLifecycleState.resumed:
        // Before any early break: an inactive→resumed blip (shade, dialog)
        // never backgrounded, but it did set the cover.
        obscured.value = false;
        final due = _relockDue();
        _backgroundedAt = null;
        if (_authInProgress) {
          // Judged once the prompt ends (see [_duringAuth]).
          _awayDuringAuth |= due;
        } else if (due) {
          locked.value = true;
        }
      // iOS snapshots the app switcher right after inactive. Android's
      // FLAG_SECURE already blanks it, and inactive fires there for
      // permission dialogs and the notification shade — no cover.
      case AppLifecycleState.inactive:
        if (enabled.value &&
            !_authInProgress &&
            defaultTargetPlatform == TargetPlatform.iOS) {
          obscured.value = true;
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Whether the app has been in the background (still, or until this
  /// resume) longer than the grace period with the lock enabled.
  bool _relockDue() {
    final since = _backgroundedAt;
    if (since == null || !enabled.value) {
      return false;
    }
    // Larger of both clocks, as for the cooldown: setting the clock back
    // must not skip the re-lock.
    final wall = _now().difference(since);
    final mono = _elapsed() - _backgroundedAtMono;
    return (wall > mono ? wall : mono) >= AppConfig.appLockGracePeriod;
  }

  /// Whether the app must be treated as locked right now — also when it
  /// is due to re-lock but hasn't seen `resumed` yet (a notification
  /// action can run first).
  bool get lockedNow =>
      enabled.value && (locked.value || (!_authInProgress && _relockDue()));

  /// Whether biometric unlock is available to offer at PIN setup.
  Future<bool> canUseBiometric() => _biometric.canAuthenticate();

  /// Whether a device screen lock exists — the only way to reset a
  /// forgotten PIN ("Forgot PIN?").
  Future<bool> canUseDeviceLock() => _biometric.canUseDeviceLock();

  /// Wrong PINs still allowed before the first cooldown (0 once throttling
  /// has begun).
  int get attemptsBeforeCooldown => math.max(0, freeAttempts - _failedAttempts);

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
  /// Also false, unchecked, while another attempt is still in flight.
  Future<bool> unlockWithPin(String pin) async {
    if (_pinInFlight || cooldownRemaining() != null) {
      return false;
    }
    _pinInFlight = true;
    try {
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
    } finally {
      _pinInFlight = false;
    }
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
    pinResetAuthorized.value = ok;
    return ok ? PinResetAuth.verified : PinResetAuth.failed;
  }

  /// Replaces the PIN after [authenticateForPinReset] and unlocks. False
  /// (PIN unchanged) when the reset is no longer authorized.
  Future<bool> resetPin(String pin) async {
    if (!pinResetAuthorized.value) {
      return false;
    }
    pinResetAuthorized.value = false;
    // Device ownership is proven: unlock before saving, so a storage error
    // in [enable] can't leave the user shut out.
    locked.value = false;
    await enable(pin, biometric: biometricEnabled.value);
    return true;
  }

  Future<bool> _duringAuth(Future<bool> Function() prompt) async {
    _authInProgress = true;
    _awayDuringAuth = false;
    var ok = false;
    try {
      return ok = await prompt();
    } finally {
      _authInProgress = false;
      if (ok) {
        // A passed prompt: any pause/resume during it belongs to it.
        _backgroundedAt = null;
      } else {
        // Failed or cancelled (e.g. by leaving the app): a pause during it
        // counts as usual. Already back → judge now; still away → cover
        // the UI and let the coming resume judge it.
        if (_awayDuringAuth) {
          locked.value = true;
        }
        if (_backgroundedAt != null && enabled.value) {
          pinResetAuthorized.value = false;
          obscured.value = true;
        }
      }
      _awayDuringAuth = false;
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
