import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/config/app_config.dart';
import 'package:productive_muslim/features/onboarding/data/app_lock_data_source.dart';
import 'package:productive_muslim/features/onboarding/domain/repositories/app_lock_repository.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FakeBiometric implements BiometricAuth {
  bool available = true;
  bool succeeds = true;
  int attempts = 0;

  @override
  Future<bool> canAuthenticate() async => available;

  bool deviceLock = true;
  bool deviceLockSucceeds = true;
  bool deviceLockThrows = false;

  @override
  Future<bool> canUseDeviceLock() async => deviceLock;

  @override
  Future<bool> authenticateWithDeviceLock(String reason) async {
    if (deviceLockThrows) {
      throw StateError('locked out');
    }
    return deviceLockSucceeds;
  }

  @override
  Future<bool> authenticate(String reason) async {
    attempts++;
    return succeeds;
  }
}

AppLockStore _store({
  BiometricAuth? biometric,
  DateTime Function()? now,
  Duration Function()? elapsed,
}) => AppLockStore(
  AppLockDataSource(SharedPreferencesAsync()),
  biometric ?? _FakeBiometric(),
  now: now,
  elapsed: elapsed,
);

final class _FakeSecureScreen implements SecureScreen {
  final calls = <bool>[];

  @override
  Future<void> setSecure({required bool on}) async => calls.add(on);
}

final class _FakeBootClock implements BootClock {
  _FakeBootClock(this.value);

  Duration value;

  @override
  Future<Duration> sinceBoot() async => value;
}

/// Biometric fake whose prompt drives lifecycle events mid-auth, like the
/// real OS sheet does on some platforms.
final class _PromptingBiometric extends _FakeBiometric {
  _PromptingBiometric(this.duringPrompt);

  final void Function() duringPrompt;

  @override
  Future<bool> authenticate(String reason) async {
    duringPrompt();
    return super.authenticate(reason);
  }
}

/// Real prefs storage whose throttle writes fail once [failWrites] is set.
final class _FlakyStorage implements AppLockStorage {
  final _inner = AppLockDataSource(SharedPreferencesAsync());
  bool failWrites = false;

  @override
  Future<({bool enabled, bool biometric})> read() => _inner.read();

  @override
  Future<void> enable(String pin, {required bool biometric}) =>
      _inner.enable(pin, biometric: biometric);

  @override
  Future<bool> verify(String pin) => _inner.verify(pin);

  @override
  Future<void> disable() => _inner.disable();

  @override
  Future<({int failedAttempts, PinCooldown? cooldown})> readThrottle() =>
      _inner.readThrottle();

  @override
  Future<void> writeThrottle({
    required int failedAttempts,
    required PinCooldown? cooldown,
  }) {
    if (failWrites) {
      throw StateError('disk full');
    }
    return _inner.writeThrottle(
      failedAttempts: failedAttempts,
      cooldown: cooldown,
    );
  }

  @override
  Future<LockScope> readScope() => _inner.readScope();

  @override
  Future<void> writeScope(LockScope scope) => _inner.writeScope(scope);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('AppLockStore', () {
    test('disabled by default; app starts unlocked', () async {
      final store = _store();
      await store.load();
      expect(store.enabled.value, isFalse);
      expect(store.locked.value, isFalse);
    });

    test('enable → reload starts locked; correct PIN unlocks', () async {
      final store = _store();
      await store.enable('1234', biometric: false);
      final fresh = _store();
      await fresh.load();
      expect(fresh.locked.value, isTrue);
      expect(await fresh.unlockWithPin('0000'), isFalse);
      expect(fresh.locked.value, isTrue);
      expect(await fresh.unlockWithPin('1234'), isTrue);
      expect(fresh.locked.value, isFalse);
    });

    test('raw PIN is never stored', () async {
      final store = _store();
      await store.enable('1234', biometric: false);
      final raw = await SharedPreferencesAsync().getString('app_lock_v1') ?? '';
      expect(raw.contains('1234'), isFalse);
    });

    test('biometric unlock honors the enabled flag', () async {
      final biometric = _FakeBiometric();
      final store = _store(biometric: biometric);
      await store.enable('1234', biometric: false);
      expect(await store.unlockWithBiometric('reason'), isFalse);
      expect(biometric.attempts, 0);
      await store.enable('1234', biometric: true);
      final fresh = AppLockStore(
        AppLockDataSource(SharedPreferencesAsync()),
        biometric,
      );
      await fresh.load();
      expect(await fresh.unlockWithBiometric('reason'), isTrue);
      expect(fresh.locked.value, isFalse);
    });

    test('disable clears the lock entirely', () async {
      final store = _store();
      await store.enable('1234', biometric: true);
      await store.disable();
      final fresh = _store();
      await fresh.load();
      expect(fresh.enabled.value, isFalse);
      expect(fresh.locked.value, isFalse);
      expect(await fresh.unlockWithPin('1234'), isFalse);
    });

    test(
      'disable turns the lock off even if the throttle reset fails',
      () async {
        final storage = _FlakyStorage();
        final store = AppLockStore(storage, _FakeBiometric());
        await store.enable('1234', biometric: false);
        expect(await store.unlockWithPin('0000'), isFalse); // a count to reset
        storage.failWrites = true;
        await store.disable();
        expect(store.enabled.value, isFalse);
        expect(store.locked.value, isFalse);
      },
    );
  });

  group('AppLockStore background re-lock', () {
    late DateTime clock;
    setUp(() => clock = DateTime(2026, 6, 1, 12));

    Future<AppLockStore> unlocked({BiometricAuth? biometric}) async {
      final store = _store(biometric: biometric, now: () => clock);
      await store.enable('1234', biometric: true);
      await store.load();
      await store.unlockWithPin('1234');
      expect(store.locked.value, isFalse);
      return store;
    }

    void background(AppLockStore store) => store
      ..onLifecycleChanged(AppLifecycleState.inactive)
      ..onLifecycleChanged(AppLifecycleState.hidden)
      ..onLifecycleChanged(AppLifecycleState.paused);

    void foreground(AppLockStore store) => store
      ..onLifecycleChanged(AppLifecycleState.hidden)
      ..onLifecycleChanged(AppLifecycleState.inactive)
      ..onLifecycleChanged(AppLifecycleState.resumed);

    test('re-locks after the grace period in the background', () async {
      final store = await unlocked();
      background(store);
      clock = clock.add(AppConfig.appLockGracePeriod);
      foreground(store);
      expect(store.locked.value, isTrue);
    });

    test('obscures the UI while not in the foreground', () async {
      final store = await unlocked();
      // Android: inactive (shade, permission dialog) leaves the UI alone.
      store.onLifecycleChanged(AppLifecycleState.inactive);
      expect(store.obscured.value, isFalse);
      store.onLifecycleChanged(AppLifecycleState.resumed);
      // iOS snapshots the app switcher on inactive: cover right away.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      store.onLifecycleChanged(AppLifecycleState.inactive);
      expect(store.obscured.value, isTrue);
      debugDefaultTargetPlatformOverride = null;
      background(store);
      expect(store.obscured.value, isTrue);
      foreground(store);
      expect(store.obscured.value, isFalse);

      await store.disable();
      background(store);
      expect(store.obscured.value, isFalse);
    });

    test('stays unlocked when back within the grace period', () async {
      final store = await unlocked();
      background(store);
      clock = clock.add(
        AppConfig.appLockGracePeriod - const Duration(seconds: 1),
      );
      foreground(store);
      expect(store.locked.value, isFalse);
    });

    test(
      'inactive alone (app switcher, notification shade) never locks',
      () async {
        final store = await unlocked();
        store.onLifecycleChanged(AppLifecycleState.inactive);
        clock = clock.add(const Duration(minutes: 5));
        store.onLifecycleChanged(AppLifecycleState.resumed);
        expect(store.locked.value, isFalse);
      },
    );

    test(
      'an auth prompt that pauses the app does not cause a re-lock',
      () async {
        late AppLockStore store;
        final biometric = _PromptingBiometric(() {
          // The OS sheet backgrounds the app for longer than the grace.
          background(store);
          clock = clock.add(const Duration(minutes: 2));
          foreground(store);
        });
        store = await unlocked(biometric: biometric);
        store.locked.value = true; // e.g. cold start
        expect(await store.unlockWithBiometric('reason'), isTrue);
        expect(store.locked.value, isFalse);
        // And the next real resume is unaffected by the prompt's pause.
        foreground(store);
        expect(store.locked.value, isFalse);
      },
    );

    test('leaving the app during a prompt still re-locks', () async {
      late AppLockStore store;
      var comeBack = true;
      final biometric = _PromptingBiometric(() {
        // Home pressed on the prompt: the OS cancels it.
        background(store);
        clock = clock.add(const Duration(hours: 2));
        if (comeBack) {
          foreground(store);
        }
      })..succeeds = false;
      store = await unlocked(biometric: biometric);

      // Prompt ended after the return: judged right away.
      expect(await store.unlockWithBiometric('reason'), isFalse);
      expect(store.locked.value, isTrue);

      // Prompt ended while still away: due now (a notification action may
      // run before resume), and the resume re-locks.
      expect(await store.unlockWithPin('1234'), isTrue);
      comeBack = false;
      expect(await store.unlockWithBiometric('reason'), isFalse);
      expect(store.locked.value, isFalse);
      expect(store.lockedNow, isTrue);
      expect(store.obscured.value, isTrue);
      foreground(store);
      expect(store.locked.value, isTrue);
    });

    test('setting the clock back does not skip the re-lock', () async {
      var mono = Duration.zero;
      final store = _store(now: () => clock, elapsed: () => mono);
      await store.enable('1234', biometric: false);
      await store.load();
      await store.unlockWithPin('1234');
      background(store);
      mono += const Duration(minutes: 10);
      clock = clock.subtract(const Duration(hours: 1));
      foreground(store);
      expect(store.locked.value, isTrue);
    });

    Future<(AppLockStore, _FakeBootClock, void Function(Duration))>
    sleepy() async {
      var mono = Duration.zero; // in-process clock: pauses in deep sleep
      final boot = _FakeBootClock(const Duration(hours: 1));
      final store = AppLockStore(
        AppLockDataSource(SharedPreferencesAsync()),
        _FakeBiometric(),
        now: () => clock,
        elapsed: () => mono,
        bootClock: boot,
      );
      await store.enable('1234', biometric: false);
      await store.load();
      await store.unlockWithPin('1234');
      return (store, boot, (Duration d) => mono += d);
    }

    test('deep sleep plus a clock set back still re-locks', () async {
      final (store, boot, awake) = await sleepy();
      background(store);
      boot.value += const Duration(minutes: 10);
      awake(const Duration(seconds: 10));
      clock = clock.subtract(const Duration(minutes: 1));
      foreground(store);
      // Nothing shows while the boot clock is read.
      expect(store.obscured.value, isTrue);
      expect(store.lockedNow, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(store.locked.value, isTrue);
      expect(store.obscured.value, isFalse);
    });

    test('a pause while the boot clock is read is not undone', () async {
      final (store, boot, awake) = await sleepy();
      background(store);
      awake(const Duration(seconds: 5));
      boot.value += const Duration(seconds: 5);
      foreground(store);
      background(store); // left again before the reading came back
      await Future<void>.delayed(Duration.zero);
      expect(store.obscured.value, isTrue);
      expect(store.lockedNow, isTrue);

      // Still within the grace period: the next resume uncovers, unlocked.
      foreground(store);
      await Future<void>.delayed(Duration.zero);
      expect(store.obscured.value, isFalse);
      expect(store.locked.value, isFalse);
      expect(store.lockedNow, isFalse);
    });

    test('leaving the app revokes a verified PIN reset', () async {
      final store = await unlocked();
      store.locked.value = true;
      expect(
        await store.authenticateForPinReset('reason'),
        PinResetAuth.verified,
      );
      expect(store.pinResetAuthorized.value, isTrue);
      background(store);
      clock = clock.add(const Duration(minutes: 5));
      foreground(store);
      expect(store.pinResetAuthorized.value, isFalse);
      expect(await store.resetPin('0000'), isFalse);
      expect(store.locked.value, isTrue);
      expect(await store.unlockWithPin('1234'), isTrue);
    });

    test('disabled lock never re-locks', () async {
      final store = _store(now: () => clock);
      await store.load();
      background(store);
      clock = clock.add(const Duration(hours: 1));
      foreground(store);
      expect(store.locked.value, isFalse);
    });
  });

  group('AppLockStore wrong-PIN throttling', () {
    late DateTime clock;
    setUp(() => clock = DateTime(2026, 6, 1, 12));

    test('cooldown schedule: 5 free attempts, then 30s, 60s, 120s…', () {
      for (var i = 0; i < 5; i++) {
        expect(AppLockStore.cooldownFor(i), isNull);
      }
      expect(AppLockStore.cooldownFor(5), const Duration(seconds: 30));
      expect(AppLockStore.cooldownFor(6), const Duration(seconds: 60));
      expect(AppLockStore.cooldownFor(7), const Duration(seconds: 120));
      expect(AppLockStore.cooldownFor(100), const Duration(seconds: 30 * 128));
    });

    test('5th wrong PIN locks input; even the right PIN is refused', () async {
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 4; i++) {
        expect(await store.unlockWithPin('0000'), isFalse);
        expect(store.lockedUntil.value, isNull);
      }
      expect(await store.unlockWithPin('0000'), isFalse);
      expect(store.lockedUntil.value, clock.add(const Duration(seconds: 30)));
      expect(await store.unlockWithPin('1234'), isFalse);
      expect(store.locked.value, isTrue);

      clock = clock.add(const Duration(seconds: 30));
      expect(await store.unlockWithPin('0000'), isFalse);
      expect(store.lockedUntil.value, clock.add(const Duration(seconds: 60)));

      clock = clock.add(const Duration(seconds: 60));
      expect(await store.unlockWithPin('1234'), isTrue);
      expect(store.lockedUntil.value, isNull);
    });

    test('a PIN attempt in flight blocks a concurrent one', () async {
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 4; i++) {
        await store.unlockWithPin('0000');
      }
      // Both would pass the cooldown check before either counted.
      final results = await Future.wait([
        store.unlockWithPin('0000'),
        store.unlockWithPin('1234'),
      ]);
      expect(results, [false, false]);
      expect(store.locked.value, isTrue);
      expect(store.lockedUntil.value, isNotNull);
    });

    test('throttle survives an app restart', () async {
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      final restarted = _store(now: () => clock);
      await restarted.load();
      expect(restarted.lockedUntil.value, isNotNull);
      expect(await restarted.unlockWithPin('1234'), isFalse);
      // The count persisted too: the next miss escalates to 60s.
      clock = clock.add(const Duration(seconds: 30));
      await restarted.unlockWithPin('0000');
      expect(
        restarted.lockedUntil.value,
        clock.add(const Duration(seconds: 60)),
      );
    });

    test('cooldown runs on the boot clock (counts sleep)', () async {
      var boot = const Duration(hours: 3);
      final store = _store(now: () => clock, elapsed: () => boot);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      expect(await store.unlockWithPin('1234'), isFalse);
      boot += const Duration(seconds: 30); // e.g. 30s asleep
      expect(await store.unlockWithPin('1234'), isTrue);
    });

    test(
      'a clock set backwards in-process cannot stretch the cooldown',
      () async {
        var mono = Duration.zero;
        final store = _store(now: () => clock, elapsed: () => mono);
        await store.enable('1234', biometric: false);
        await store.load();
        for (var i = 0; i < 5; i++) {
          await store.unlockWithPin('0000');
        }
        clock = clock.subtract(const Duration(days: 1));
        mono += const Duration(seconds: 30); // real time passes
        expect(await store.unlockWithPin('1234'), isTrue);
      },
    );

    test('a clock set forward does not end the wait', () async {
      const boot = Duration(hours: 3);
      final store = _store(now: () => clock, elapsed: () => boot);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      clock = clock.add(const Duration(days: 1));
      expect(store.cooldownRemaining(), const Duration(seconds: 30));
      expect(await store.unlockWithPin('1234'), isFalse);
    });

    test('a clock set forward plus a restart does not end the wait', () async {
      const boot = Duration(hours: 3);
      final store = _store(now: () => clock, elapsed: () => boot);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      clock = clock.add(const Duration(days: 1));
      final restarted = _store(now: () => clock, elapsed: () => boot);
      await restarted.load();
      expect(restarted.cooldownRemaining(), const Duration(seconds: 30));
    });

    test('a restart resumes the persisted remainder', () async {
      var boot = const Duration(hours: 3);
      final store = _store(now: () => clock, elapsed: () => boot);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      boot += const Duration(seconds: 10);
      final restarted = _store(now: () => clock, elapsed: () => boot);
      await restarted.load();
      expect(restarted.cooldownRemaining(), const Duration(seconds: 20));
    });

    test('after a reboot the whole remainder is due again, and a later '
        'restart measures from the new boot', () async {
      var boot = const Duration(hours: 3);
      final store = _store(now: () => clock, elapsed: () => boot);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      boot += const Duration(seconds: 10);
      final sameBoot = _store(now: () => clock, elapsed: () => boot);
      await sameBoot.load();
      expect(sameBoot.cooldownRemaining(), const Duration(seconds: 20));

      boot = const Duration(seconds: 5); // rebooted: clock below the start
      final rebooted = _store(now: () => clock, elapsed: () => boot);
      await rebooted.load();
      expect(rebooted.cooldownRemaining(), const Duration(seconds: 30));

      boot += const Duration(seconds: 12);
      final again = _store(now: () => clock, elapsed: () => boot);
      await again.load();
      expect(again.cooldownRemaining(), const Duration(seconds: 18));
    });

    test('secure screen follows the lock being on', () async {
      final secure = _FakeSecureScreen();
      final store = AppLockStore(
        AppLockDataSource(SharedPreferencesAsync()),
        _FakeBiometric(),
        secureScreen: secure,
      );
      await store.load();
      store.watchLifecycle();
      await store.enable('1234', biometric: false);
      await store.disable();
      store.dispose();
      expect(secure.calls, [false, true, false]);
    });

    test('the boot clock is read on load and before each PIN check', () async {
      final bootClock = _FakeBootClock(const Duration(hours: 3));
      final store = AppLockStore(
        AppLockDataSource(SharedPreferencesAsync()),
        _FakeBiometric(),
        bootClock: bootClock,
      );
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      expect(await store.unlockWithPin('1234'), isFalse);
      // Slept 30s: the in-process stopwatch barely moved, the boot clock did.
      bootClock.value += const Duration(seconds: 31);
      expect(await store.unlockWithPin('1234'), isTrue);
    });

    test(
      'a pre-boot-clock (wall time) record still owes its remainder',
      () async {
        await SharedPreferencesAsync().setString(
          'app_lock_throttle_v1',
          jsonEncode({
            'failed': 5,
            'untilMs': DateTime.now()
                .add(const Duration(seconds: 20))
                .millisecondsSinceEpoch,
          }),
        );
        final store = _store(elapsed: () => const Duration(hours: 3));
        await store.load();
        final left = store.cooldownRemaining();
        expect(left, isNotNull);
        expect(left! > const Duration(seconds: 15), isTrue);
      },
    );

    test('a clock set backwards cannot stretch a persisted cooldown', () async {
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      clock = clock.subtract(const Duration(days: 365));
      final restarted = _store(now: () => clock);
      await restarted.load();
      // Clamped to the 30s this attempt count earns, not a year.
      expect(restarted.cooldownRemaining(), const Duration(seconds: 30));
    });

    test('a failed throttle reset still unlocks (PIN and biometric), and '
        'the persisted count survives', () async {
      final storage = _FlakyStorage();
      final store = AppLockStore(storage, _FakeBiometric(), now: () => clock);
      await store.enable('1234', biometric: true);
      await store.load();
      await store.unlockWithPin('0000');
      storage.failWrites = true;
      expect(await store.unlockWithPin('1234'), isTrue);
      expect(store.locked.value, isFalse);

      final fresh = AppLockStore(storage, _FakeBiometric(), now: () => clock);
      await fresh.load();
      expect(await fresh.unlockWithBiometric('reason'), isTrue);
      expect(fresh.locked.value, isFalse);
      // The unsaved reset never loosens throttling after a restart.
      storage.failWrites = false;
      final restarted = AppLockStore(storage, _FakeBiometric());
      await restarted.load();
      expect(restarted.attemptsBeforeCooldown, AppLockStore.freeAttempts - 1);
    });

    test('a correct PIN resets the attempt count', () async {
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 4; i++) {
        await store.unlockWithPin('0000');
      }
      expect(await store.unlockWithPin('1234'), isTrue);
      await store.unlockWithPin('0000');
      expect(store.lockedUntil.value, isNull);
    });
  });

  group('AppLockStore PIN storage & reset', () {
    test('legacy timestamp-salted hash still verifies', () async {
      // Format written by earlier versions: salt = base36 timestamp.
      const salt = 'lz3k9q0abc';
      final hash = sha256.convert(utf8.encode('$salt:4321')).toString();
      await SharedPreferencesAsync().setString(
        'app_lock_v1',
        jsonEncode({'salt': salt, 'hash': hash, 'biometric': false}),
      );
      final store = _store();
      await store.load();
      expect(store.locked.value, isTrue);
      expect(await store.unlockWithPin('1111'), isFalse);
      expect(await store.unlockWithPin('4321'), isTrue);
    });

    test('new salts are random, not timestamps', () async {
      final store = _store();
      final salts = <String>{};
      for (var i = 0; i < 5; i++) {
        await store.enable('1234', biometric: false);
        final raw = await SharedPreferencesAsync().getString('app_lock_v1');
        final salt = (jsonDecode(raw!) as Map)['salt'] as String;
        expect(base64Url.decode(salt), hasLength(16));
        salts.add(salt);
      }
      expect(salts, hasLength(5));
    });

    test('forgot PIN: device lock verifies, new PIN unlocks', () async {
      final biometric = _FakeBiometric();
      final store = _store(biometric: biometric);
      await store.enable('1234', biometric: false);
      await store.load();
      expect(
        await store.authenticateForPinReset('reason'),
        PinResetAuth.verified,
      );
      expect(await store.resetPin('9876'), isTrue);
      expect(store.locked.value, isFalse);
      final fresh = _store(biometric: biometric);
      await fresh.load();
      expect(await fresh.unlockWithPin('1234'), isFalse);
      expect(await fresh.unlockWithPin('9876'), isTrue);
    });

    test('corrupt lock prefs fail closed instead of crashing', () async {
      await SharedPreferencesAsync().setString('app_lock_v1', '{"hash":');
      await SharedPreferencesAsync().setString('app_lock_throttle_v1', '[1');
      final store = _store();
      await store.load();
      expect(store.enabled.value, isTrue);
      expect(store.locked.value, isTrue);
      expect(await store.unlockWithPin('1234'), isFalse);
      expect(
        await store.authenticateForPinReset('reason'),
        PinResetAuth.verified,
      );
      expect(await store.resetPin('9876'), isTrue);
      expect(store.locked.value, isFalse);
    });

    test('forgot PIN without a device screen lock is reported', () async {
      final biometric = _FakeBiometric()..deviceLock = false;
      final store = _store(biometric: biometric);
      await store.enable('1234', biometric: false);
      await store.load();
      expect(
        await store.authenticateForPinReset('reason'),
        PinResetAuth.noDeviceLock,
      );
      expect(store.locked.value, isTrue);
    });

    test('failed device-lock auth leaves the PIN unchanged', () async {
      final biometric = _FakeBiometric()..deviceLockSucceeds = false;
      final store = _store(biometric: biometric);
      await store.enable('1234', biometric: false);
      await store.load();
      expect(
        await store.authenticateForPinReset('reason'),
        PinResetAuth.failed,
      );
      expect(await store.unlockWithPin('1234'), isTrue);
    });

    test(
      'a locked-out device lock reports unavailable, PIN unchanged',
      () async {
        final biometric = _FakeBiometric()..deviceLockThrows = true;
        final store = _store(biometric: biometric);
        await store.enable('1234', biometric: false);
        await store.load();
        expect(
          await store.authenticateForPinReset('reason'),
          PinResetAuth.unavailable,
        );
        expect(await store.resetPin('9999'), isFalse);
        expect(await store.unlockWithPin('1234'), isTrue);
      },
    );
  });

  group('Muhasaba-only scope', () {
    test('locks only the section, persisted across restarts', () async {
      final store = _store();
      await store.enable('1234', biometric: false);
      await store.setScope(LockScope.muhasaba);
      expect(store.muhasabaLocked, isFalse); // this session stays open

      final restarted = _store();
      await restarted.load();
      expect(restarted.scope.value, LockScope.muhasaba);
      expect(restarted.locked.value, isFalse);
      // Muhasaba is off limits ("Mark as prayed" refuses), the app isn't.
      expect(restarted.lockedNow, isTrue);
      expect(restarted.muhasabaLocked, isTrue);

      expect(await restarted.unlockWithPin('1234'), isTrue);
      expect(restarted.muhasabaLocked, isFalse);
      expect(restarted.lockedNow, isFalse);
    });

    test('backgrounding past the grace period re-locks the section', () async {
      var clock = DateTime(2026);
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.setScope(LockScope.muhasaba);
      store
        ..onLifecycleChanged(AppLifecycleState.hidden)
        ..onLifecycleChanged(AppLifecycleState.paused);
      clock = clock.add(AppConfig.appLockGracePeriod);
      store.onLifecycleChanged(AppLifecycleState.resumed);
      expect(store.muhasabaLocked, isTrue);
      expect(store.locked.value, isFalse);
    });

    test(
      'changing the scope never unlocks: a locked section stays locked',
      () async {
        final store = _store();
        await store.enable('1234', biometric: false);
        await store.setScope(LockScope.muhasaba);
        await store.load(); // fresh start: section locked
        expect(store.muhasabaLocked, isTrue);
        expect(store.lockedNow, isTrue); // notification actions refuse too

        await store.setScope(LockScope.app);
        expect(store.locked.value, isTrue);
        expect(store.sectionLocked.value, isFalse);
        expect(store.lockedNow, isTrue);

        expect(await store.unlockWithPin('1234'), isTrue);
        expect(store.lockedNow, isFalse);
      },
    );

    test('an unknown stored scope reads as the whole app', () async {
      final store = _store();
      await store.enable('1234', biometric: false);
      await SharedPreferencesAsync().setString('app_lock_scope_v1', 'future');
      await store.load();
      expect(store.scope.value, LockScope.app);
      expect(store.locked.value, isTrue);
      expect(LockScope.fromCode(null), LockScope.app);
      expect(LockScope.fromCode('muhasaba'), LockScope.muhasaba);
    });

    test('turning the lock off forgets the scope', () async {
      final store = _store();
      await store.enable('1234', biometric: false);
      await store.setScope(LockScope.muhasaba);
      await store.disable();
      await store.enable('5678', biometric: false);
      await store.load();
      expect(store.scope.value, LockScope.app);
      expect(store.sectionLocked.value, isFalse);
    });
  });
}
