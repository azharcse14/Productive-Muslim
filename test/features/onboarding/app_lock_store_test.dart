import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/onboarding/data/app_lock_data_source.dart';
import 'package:qalbee/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FakeBiometric implements BiometricAuth {
  bool available = true;
  bool succeeds = true;
  int attempts = 0;

  @override
  Future<bool> canAuthenticate() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    attempts++;
    return succeeds;
  }
}

AppLockStore _store({BiometricAuth? biometric}) => AppLockStore(
      AppLockDataSource(SharedPreferencesAsync()),
      biometric ?? _FakeBiometric(),
    );

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
      final raw =
          await SharedPreferencesAsync().getString('app_lock_v1') ?? '';
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
}
