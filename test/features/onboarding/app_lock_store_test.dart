import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/config/app_config.dart';
import 'package:productive_muslim/features/onboarding/data/app_lock_data_source.dart';
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

  @override
  Future<bool> canUseDeviceLock() async => deviceLock;

  @override
  Future<bool> authenticateWithDeviceLock(String reason) async =>
      deviceLockSucceeds;

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

    test(
      'cooldown keeps running while the device sleeps (monotonic paused)',
      () async {
        const mono = Duration.zero; // monotonic clock frozen during sleep
        final store = _store(now: () => clock, elapsed: () => mono);
        await store.enable('1234', biometric: false);
        await store.load();
        for (var i = 0; i < 5; i++) {
          await store.unlockWithPin('0000');
        }
        expect(await store.unlockWithPin('1234'), isFalse);
        clock = clock.add(const Duration(seconds: 30)); // wall time passes
        expect(await store.unlockWithPin('1234'), isTrue);
      },
    );

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

    test('accepted trade-off: a clock set forward ends the current wait, '
        'but the next wrong PIN still escalates', () async {
      const mono = Duration.zero;
      final store = _store(now: () => clock, elapsed: () => mono);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      clock = clock.add(const Duration(days: 1));
      expect(store.cooldownRemaining(), isNull);
      await store.unlockWithPin('0000'); // 6th wrong → 60s
      expect(store.cooldownRemaining(), const Duration(seconds: 60));
    });

    test('a restart resumes the persisted remainder', () async {
      final store = _store(now: () => clock);
      await store.enable('1234', biometric: false);
      await store.load();
      for (var i = 0; i < 5; i++) {
        await store.unlockWithPin('0000');
      }
      clock = clock.add(const Duration(seconds: 10));
      final restarted = _store(now: () => clock);
      await restarted.load();
      expect(restarted.cooldownRemaining(), const Duration(seconds: 20));
    });

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
  });
}
