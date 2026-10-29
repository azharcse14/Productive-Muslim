import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/onboarding/data/app_lock_data_source.dart';
import 'package:productive_muslim/features/onboarding/presentation/screens/lock_screen.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/lock_fakes.dart';

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const LockScreen(),
);

late DateTime _clock;

Future<AppLockStore> _register(FakeBiometric biometric) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  _clock = DateTime(2026, 6, 1, 12);
  final store = AppLockStore(
    AppLockDataSource(SharedPreferencesAsync()),
    biometric,
    now: () => _clock,
  );
  await store.enable('1234', biometric: false);
  await store.load();
  GetIt.I.registerSingleton<AppLockStore>(store);
  return store;
}

Future<void> _enter(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
}

void main() {
  tearDown(() => GetIt.I.reset());

  testWidgets('throttled: shows remaining time and ignores digits', (
    tester,
  ) async {
    final store = await _register(FakeBiometric());
    await tester.runAsync(() async {
      for (var i = 0; i < AppLockStore.freeAttempts; i++) {
        await store.unlockWithPin('0000');
      }
    });
    await tester.pumpWidget(_app());
    await tester.pump();
    final message = find.byKey(const ValueKey('lock-message'));
    expect(
      tester.widget<Text>(message).data,
      'Too many attempts. Try again in 0:30.',
    );
    await _enter(tester, '1234');
    expect(store.locked.value, isTrue);
    // The countdown ticks.
    _clock = _clock.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(message).data,
      'Too many attempts. Try again in 0:28.',
    );
    await tester.pumpWidget(const SizedBox()); // cancels the ticker
  });

  testWidgets('forgot PIN: device lock, then a new PIN unlocks', (
    tester,
  ) async {
    final store = await _register(FakeBiometric());
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();
    expect(find.text('Set a new 4-digit PIN'), findsOneWidget);
    expect(find.text('Forgot PIN?'), findsNothing);
    await _enter(tester, '9876');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await tester.runAsync(() => _enter(tester, '9876'));
    await tester.pump();
    expect(store.locked.value, isFalse);
    expect(await tester.runAsync(() => store.unlockWithPin('9876')), isTrue);
  });

  testWidgets('leaving the app mid-reset returns to PIN entry', (tester) async {
    final store = await _register(FakeBiometric());
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();
    expect(find.text('Set a new 4-digit PIN'), findsOneWidget);
    store
      ..onLifecycleChanged(AppLifecycleState.hidden)
      ..onLifecycleChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Set a new 4-digit PIN'), findsNothing);
    expect(find.text('Forgot PIN?'), findsOneWidget);
  });

  testWidgets('forgot PIN without a device screen lock explains why', (
    tester,
  ) async {
    final store = await _register(FakeBiometric()..deviceLock = false);
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();
    expect(find.text("Can't reset the PIN here"), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(store.locked.value, isTrue);
  });

  testWidgets('verify mode (turning the lock off) pops true only on the PIN', (
    tester,
  ) async {
    final store = await _register(FakeBiometric());
    await store.unlockWithPin('1234'); // in the app, unlocked
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const LockScreen(mode: LockScreenMode.verify),
                ),
              );
            },
            child: const Text('off'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('off'));
    await tester.pumpAndSettle();
    // No reset path here: it would skip proving the PIN.
    expect(find.text('Forgot PIN?'), findsNothing);
    await tester.runAsync(() => _enter(tester, '0000'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    expect(result, isNull);
    await tester.runAsync(() => _enter(tester, '1234'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
    expect(result, isTrue);
    // Backing out instead reports no verification.
    await tester.tap(find.text('off'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('from the third miss, warns how many tries remain', (
    tester,
  ) async {
    await _register(FakeBiometric());
    await tester.pumpWidget(_app());
    await tester.pump();
    final message = find.byKey(const ValueKey('lock-message'));
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(() => _enter(tester, '0000'));
      await tester.pump();
    }
    expect(tester.widget<Text>(message).data, 'Wrong PIN — try again');
    await tester.runAsync(() => _enter(tester, '0000'));
    await tester.pump();
    expect(
      tester.widget<Text>(message).data,
      'Wrong PIN — 2 attempts left before a wait',
    );
  });

  testWidgets('a cancelled forgot-PIN check says so', (tester) async {
    await _register(FakeBiometric()..deviceLockSucceeds = false);
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pump();
    expect(
      find.text("Couldn't confirm it's you. Your PIN is unchanged."),
      findsOneWidget,
    );
  });

  testWidgets('setup without a device lock needs an acknowledgement', (
    tester,
  ) async {
    await _register(FakeBiometric()..deviceLock = false);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const LockScreen(mode: LockScreenMode.setup),
              ),
            ),
            child: const Text('on'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('on'));
    await tester.pumpAndSettle();
    expect(find.text('No screen lock on this device'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);
    await tester.tap(find.text('on'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(find.text('Set a 4-digit PIN'), findsOneWidget);
  });
}
