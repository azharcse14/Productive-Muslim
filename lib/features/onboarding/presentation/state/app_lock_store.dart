import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/app_config.dart';
import '../../domain/repositories/app_lock_repository.dart';

/// Outcome of the "Forgot PIN?" device-lock check.
/// [unavailable]: the screen lock can't be used right now (e.g. locked
/// out after too many tries).
enum PinResetAuth { verified, failed, noDeviceLock, unavailable }

/// App-lock state: whether the app is locked right now and the
/// enable/verify flows. The router redirect watches [locked].
///
/// Re-locks after the app has been in the background longer than
/// [AppConfig.appLockGracePeriod]; wrong PINs are throttled with a
/// persisted, growing cooldown.
///
/// With [scope] [LockScope.muhasaba] the app itself never locks: the same
/// PIN guards only the Muhasaba section ([sectionLocked]), once per
/// foreground session, re-locking on the same background rule.
final class AppLockStore implements SectionLockStatus {
  AppLockStore(
    this._source,
    this._biometric, {
    DateTime Function()? now,
    Duration Function()? elapsed,
    BootClock? bootClock,
    SecureScreen? secureScreen,
  }) : _now = now ?? DateTime.now,
       _secureScreen = secureScreen,
       _injectedElapsed = elapsed ?? (now == null ? null : _since(now)),
       _bootClock = bootClock;

  final AppLockStorage _source;
  final BiometricAuth _biometric;
  final DateTime Function() _now;
  final Duration Function()? _injectedElapsed;
  final BootClock? _bootClock;
  final SecureScreen? _secureScreen;
  EffectCleanup? _secureEffect;

  /// Last [BootClock] reading, advanced in-process by [_sinceBootBase]
  /// between readings (that stopwatch pauses in deep sleep, so it can only
  /// lag the boot clock — stricter, never looser; [_syncBootClock] catches
  /// it up on resume and before each PIN check).
  Duration _bootBase = Duration.zero;
  final _sinceBootBase = Stopwatch()..start();

  /// Monotonic time since boot — immune to wall-clock changes. Tests inject
  /// it ([elapsed]); those that inject only [now] get it from that clock.
  Duration _elapsed() =>
      _injectedElapsed?.call() ?? _bootBase + _sinceBootBase.elapsed;

  Future<void> _syncBootClock() async {
    final clock = _bootClock;
    if (clock == null) {
      return;
    }
    try {
      final boot = await clock.sinceBoot();
      if (boot > _elapsed()) {
        _bootBase = boot;
        _sinceBootBase.reset();
      }
    } on Object catch (e) {
      // Stopwatch only: lags across sleep, and a restart reads as a
      // reboot (full remainder) — stricter, so just logged.
      debugPrint('app lock: boot clock unavailable: $e');
    }
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
  /// Always false with [LockScope.muhasaba].
  late final locked = signal(false);

  /// What the lock guards.
  late final scope = signal(LockScope.app);

  /// True while the Muhasaba section needs the PIN ([LockScope.muhasaba]).
  late final sectionLocked = signal(false);

  @override
  bool get muhasabaLocked => enabled.value && sectionLocked.value;

  bool get _appScope => scope.value == LockScope.app;

  /// Locks whatever [scope] guards.
  void _relock() {
    if (_appScope) {
      locked.value = true;
    } else {
      sectionLocked.value = true;
    }
  }

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

  /// Current cooldown: its length and start on the boot clock only, so
  /// moving the wall clock either way neither skips nor stretches it.
  Duration? _cooldownSpan;
  Duration _cooldownStartMono = Duration.zero;
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
    if (lockedUntil.value == null || span == null) {
      return null;
    }
    final served = _elapsed() - _cooldownStartMono;
    final left = served.isNegative ? span : span - served;
    return left > Duration.zero ? left : null;
  }

  /// Starts (or clears) a cooldown of [span] from now on the boot clock.
  void _startCooldown(Duration? span) {
    _cooldownSpan = span;
    _cooldownStartMono = _elapsed();
    lockedUntil.value = span == null ? null : _now().add(span);
  }

  PinCooldown? get _persistedCooldown {
    final span = _cooldownSpan;
    return span == null
        ? null
        : (startedAtBoot: _cooldownStartMono, left: span);
  }

  Future<void> load() async {
    await _syncBootClock();
    final state = await _source.read();
    enabled.value = state.enabled;
    biometricEnabled.value = state.biometric;
    try {
      scope.value = await _source.readScope();
    } on Object catch (e) {
      // Fail closed: the whole app locks.
      debugPrint('app lock: scope unreadable: $e');
      scope.value = LockScope.app;
    }
    locked.value = state.enabled && _appScope;
    sectionLocked.value = state.enabled && !_appScope;
    final ({int failedAttempts, PinCooldown? cooldown}) throttle;
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
    // count can earn. Served time counts only on the same boot: a boot
    // clock below the recorded start means a reboot (or an unknown start),
    // and then the whole remainder is due again.
    final saved = throttle.cooldown;
    final cap = cooldownFor(_failedAttempts);
    if (saved == null || cap == null) {
      _startCooldown(null);
      return;
    }
    final start = saved.startedAtBoot;
    final now = _elapsed();
    final served = start != null && now >= start ? now - start : Duration.zero;
    final left = saved.left - served;
    _startCooldown(left <= Duration.zero ? null : (left > cap ? cap : left));
    if (start == null || now < start) {
      // Re-anchor on this boot, or a later restart would measure from the
      // old boot's start.
      try {
        await _persistThrottle();
      } on Object catch (e) {
        debugPrint('app lock: cooldown not re-anchored: $e');
      }
    }
  }

  Future<void> _persistThrottle() => _source.writeThrottle(
    failedAttempts: _failedAttempts,
    cooldown: _persistedCooldown,
  );

  /// Starts watching app lifecycle for background re-locking. Call once.
  /// Also keeps [SecureScreen] in step with [enabled].
  void watchLifecycle() {
    _lifecycle ??= AppLifecycleListener(onStateChange: onLifecycleChanged);
    final secure = _secureScreen;
    if (secure != null) {
      _secureEffect ??= effect(
        () => unawaited(secure.setSecure(on: enabled.value)),
      );
    }
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
        // The in-process stopwatch paused if the device slept.
        unawaited(_syncBootClock());
        // Before any early break: an inactive→resumed blip (shade, dialog)
        // never backgrounded, but it did set the cover.
        obscured.value = false;
        final due = _relockDue();
        _backgroundedAt = null;
        if (_authInProgress) {
          // Judged once the prompt ends (see [_duringAuth]).
          _awayDuringAuth |= due;
        } else if (due) {
          _relock();
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

  /// Whether what the lock guards (the app, or just Muhasaba) must be
  /// treated as locked right now — also when it is due to re-lock but
  /// hasn't seen `resumed` yet (a notification action can run first).
  /// Either way Muhasaba data is off limits.
  bool get lockedNow =>
      enabled.value &&
      ((_appScope ? locked.value : sectionLocked.value) ||
          (!_authInProgress && _relockDue()));

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
    // Storage says off: memory follows before anything else can throw.
    enabled.value = false;
    biometricEnabled.value = false;
    locked.value = false;
    scope.value = LockScope.app;
    sectionLocked.value = false;
    try {
      await _resetThrottle();
    } on Object catch (e) {
      // No PIN is left to throttle; a stale count only matters if a new
      // PIN is set, and [enable] resets it again.
      debugPrint('app lock: throttle reset not saved: $e');
    }
  }

  /// Switches what the lock guards; the caller proves the PIN first when
  /// narrowing it to Muhasaba. Never unlocks anything: a locked state
  /// moves over to the new scope.
  Future<void> setScope(LockScope next) async {
    await _source.writeScope(next);
    final wasLocked = locked.value || sectionLocked.value;
    scope.value = next;
    locked.value = next == LockScope.app && wasLocked;
    sectionLocked.value = next == LockScope.muhasaba && wasLocked;
  }

  /// Verifies [pin]. Always false while throttled ([lockedUntil] in the
  /// future) — the PIN is not even checked.
  /// Also false, unchecked, while another attempt is still in flight.
  Future<bool> unlockWithPin(String pin) async {
    if (_pinInFlight) {
      return false;
    }
    _pinInFlight = true;
    try {
      await _syncBootClock();
      if (cooldownRemaining() != null) {
        return false;
      }
      final ok = await _source.verify(pin);
      if (ok) {
        await _unlock();
        return true;
      }
      _failedAttempts++;
      _startCooldown(cooldownFor(_failedAttempts));
      await _persistThrottle();
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
      await _unlock();
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
    final bool ok;
    try {
      ok = await _duringAuth(
        () => _biometric.authenticateWithDeviceLock(reason),
      );
    } on Object catch (e) {
      debugPrint('PIN reset auth: $e');
      pinResetAuthorized.value = false;
      return PinResetAuth.unavailable;
    }
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
    sectionLocked.value = false;
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
          _relock();
        }
        if (_backgroundedAt != null && enabled.value) {
          pinResetAuthorized.value = false;
          obscured.value = true;
        }
      }
      _awayDuringAuth = false;
    }
  }

  /// Proven owner: unlock before saving, so a storage error can't leave
  /// the user shut out. A failed write keeps the old persisted count —
  /// stricter after a restart, never looser — so it is only logged.
  Future<void> _unlock() async {
    locked.value = false;
    sectionLocked.value = false;
    try {
      await _resetThrottle();
    } on Object catch (e) {
      debugPrint('app lock: throttle reset not saved: $e');
    }
  }

  Future<void> _resetThrottle() async {
    if (_failedAttempts == 0 && lockedUntil.value == null) {
      return;
    }
    _failedAttempts = 0;
    _startCooldown(null);
    await _persistThrottle();
  }

  void dispose() {
    _lifecycle?.dispose();
    _secureEffect?.call();
  }
}
