import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/onboarding/data/app_lock_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Map-backed store: two of these are two separate files, as on Android.
final class _MapPrefs implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a lock in the old shared store moves to its own store', () async {
    final legacy = _MapPrefs();
    await AppLockDataSource(legacy).enable('1234', biometric: true);
    legacy.values['other'] = 'kept';

    final own = _MapPrefs();
    final source = AppLockDataSource(own, legacy: legacy);

    expect(await source.read(), (enabled: true, biometric: true));
    expect(await source.verify('1234'), isTrue);
    expect(legacy.values.keys, ['other']);
    expect(own.values.keys, ['app_lock_v1']);
  });

  for (final raw in [
    'not json',
    '{"salt":"s","biometric":true}',
    '{"hash":1}',
  ]) {
    test('a stored payload without a PIN hash fails closed: $raw', () async {
      final own = _MapPrefs()..values['app_lock_v1'] = raw;
      final source = AppLockDataSource(own);
      expect(await source.read(), (enabled: true, biometric: false));
      expect(await source.verify(''), isFalse);
    });
  }

  test('the own store wins over a stale legacy copy', () async {
    final own = _MapPrefs();
    await AppLockDataSource(own).enable('1111', biometric: false);
    final legacy = _MapPrefs();
    await AppLockDataSource(legacy).enable('2222', biometric: false);

    final source = AppLockDataSource(own, legacy: legacy);
    expect(await source.verify('1111'), isTrue);
    expect(legacy.values, isEmpty);
  });

  test('iOS: the lock moves from UserDefaults into the Keychain', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final keychain = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.productivemuslim.app/keychain'),
          (call) async {
            final args = (call.arguments as Map).cast<String, String>();
            return switch (call.method) {
              'get' => keychain[args['key']],
              'set' => keychain[args['key']!] = args['value']!,
              _ => keychain.remove(args['key']),
            };
          },
        );
    final legacy = SharedPreferencesAsync();
    await AppLockDataSource(legacy).enable('1234', biometric: false);

    final source = AppLockDataSource(KeychainPrefs(), legacy: legacy);
    expect(await source.verify('1234'), isTrue);
    expect(keychain.keys, ['app_lock_v1']);
    expect(await legacy.getString('app_lock_v1'), isNull);
  });
}
