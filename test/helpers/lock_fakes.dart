import 'package:productive_muslim/features/onboarding/data/app_lock_data_source.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class FakeBiometric implements BiometricAuth {
  FakeBiometric({this.available = false, this.succeeds = false});

  bool available;
  bool succeeds;

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
  Future<bool> authenticate(String reason) async => succeeds;
}

/// A loaded [AppLockStore] over in-memory prefs (also resets the global
/// prefs platform — call before other prefs-dependent fakes if order
/// matters).
Future<AppLockStore> makeAppLockStore({bool withPin = false}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = AppLockStore(
    AppLockDataSource(SharedPreferencesAsync()),
    FakeBiometric(),
  );
  if (withPin) {
    await store.enable('1234', biometric: false);
  }
  await store.load();
  return store;
}
