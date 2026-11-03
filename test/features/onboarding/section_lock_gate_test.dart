import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/config/app_config.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/onboarding/data/app_lock_data_source.dart';
import 'package:productive_muslim/features/onboarding/domain/repositories/app_lock_repository.dart';
import 'package:productive_muslim/features/onboarding/presentation/screens/lock_screen.dart';
import 'package:productive_muslim/features/onboarding/presentation/screens/section_lock_gate.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/lock_fakes.dart';

void main() {
  late AppLockStore store;
  var clock = DateTime(2026);

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    clock = DateTime(2026);
    store = AppLockStore(
      AppLockDataSource(SharedPreferencesAsync()),
      FakeBiometric(),
      now: () => clock,
    );
    await store.enable('1234', biometric: false);
    await store.setScope(LockScope.muhasaba);
    await store.load(); // a fresh start: the section is locked
    // The pushed LockScreen resolves the store itself.
    GetIt.I.registerSingleton<AppLockStore>(store);
  });

  tearDown(() => GetIt.I.reset());

  Widget app() => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SectionLockGate(
      lock: store,
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const Text('secret deeds'),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Text('tracker editor')),
                  ),
                ),
                child: const Text('open page'),
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(content: Text('a sheet')),
                ),
                child: const Text('open dialog'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> unlock(WidgetTester tester) async {
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  void relock() {
    store
      ..onLifecycleChanged(AppLifecycleState.hidden)
      ..onLifecycleChanged(AppLifecycleState.paused);
    clock = clock.add(AppConfig.appLockGracePeriod);
    store.onLifecycleChanged(AppLifecycleState.resumed);
  }

  testWidgets('locked → PIN → content', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Muhasaba is locked'), findsOneWidget);
    expect(find.text('secret deeds'), findsNothing);

    await unlock(tester);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('secret deeds'), findsOneWidget);
  });

  testWidgets('a double tap opens one lock screen; it offers Forgot PIN', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Unlock'));
    await tester.tap(find.text('Unlock'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Forgot PIN?'), findsOneWidget);
  });

  testWidgets('backgrounding past the grace period locks it again', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await unlock(tester);

    relock();
    await tester.pump();
    expect(find.text('secret deeds'), findsNothing);
    expect(find.text('Muhasaba is locked'), findsOneWidget);
  });

  testWidgets('a re-lock closes pages and dialogs opened on top', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await unlock(tester);
    await tester.tap(find.text('open page'));
    await tester.pumpAndSettle();
    expect(find.text('tracker editor'), findsOneWidget);

    relock();
    await tester.pumpAndSettle();
    expect(find.text('tracker editor'), findsNothing);
    expect(find.text('Muhasaba is locked'), findsOneWidget);

    await unlock(tester);
    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('a sheet'), findsOneWidget);
    relock();
    await tester.pumpAndSettle();
    expect(find.text('a sheet'), findsNothing);
    expect(find.text('Muhasaba is locked'), findsOneWidget);
  });

  testWidgets('whole-app scope never shows the section gate', (tester) async {
    await store.unlockWithPin('1234');
    await store.setScope(LockScope.app);
    await tester.pumpWidget(app());
    expect(find.text('secret deeds'), findsOneWidget);
  });
}
