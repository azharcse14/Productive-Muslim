import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/health/presentation/screens/health_screen.dart';
import 'package:productive_muslim/features/health/presentation/state/health_store.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/muhasaba_fakes.dart';
import '../../helpers/tracker_screen_matrix.dart';

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const HealthScreen(),
);

void main() {
  late HealthStore health;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final (muhasaba, _) = await makeMuhasabaStore(
      now: () => DateTime(2026, 10, 29, 9),
    );
    health = HealthStore(
      SharedPreferencesAsync(),
      now: () => DateTime(2026, 10, 29, 9),
    );
    GetIt.I
      ..registerSingleton<MuhasabaStore>(muhasaba)
      ..registerSingleton<HealthStore>(health);
  });

  tearDown(() async {
    GetIt.I<MuhasabaStore>().dispose();
    await GetIt.I.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
  }

  testWidgets('a past day can be picked and its weight logged', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Log another day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Weight · Oct 20'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '71.2');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(health.weightOn(DateTime(2026, 10, 20)), 71.2);
  });

  testWidgets('tapping a history row edits that day', (tester) async {
    await health.setWeight(DateTime(2026, 10, 20), 70);
    await health.setWeight(DateTime(2026, 10, 29), 69);
    await pumpScreen(tester);

    await tester.tap(find.text('Oct 20 · 70.0 kg'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '70.5');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(health.weightOn(DateTime(2026, 10, 20)), 70.5);
    expect(health.weightOn(DateTime(2026, 10, 29)), 69);
  });

  testWidgets('the newest weight from an earlier day is editable', (
    tester,
  ) async {
    await health.setWeight(DateTime(2026, 10, 20), 70);
    await health.setWeight(DateTime(2026, 10, 25), 69);
    await pumpScreen(tester);

    expect(find.text("Log today's weight"), findsOneWidget);
    await tester.tap(find.text('Oct 25 · 69.0 kg'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '68.5');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(health.weightOn(DateTime(2026, 10, 25)), 68.5);
    expect(health.weightOn(DateTime(2026, 10, 29)), isNull);
  });

  screenMatrix(
    'HealthScreen',
    () => const HealthScreen(),
    setUpCase: () async {
      await health.setWeight(DateTime(2026, 10, 20), 70);
      await health.setWeight(DateTime(2026, 10, 29), 69.4);
    },
  );
}
