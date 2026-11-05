import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/achievements/domain/achievements.dart';
import 'package:productive_muslim/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:productive_muslim/features/achievements/presentation/state/achievement_store.dart';
import 'package:productive_muslim/features/achievements/presentation/widgets/achievement_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/muhasaba_fakes.dart';
import '../../helpers/tracker_screen_matrix.dart';

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const AchievementsScreen(),
);

Future<AchievementStore> _registerStore() async {
  final store = AchievementStore(
    muhasaba: InMemoryMuhasabaRepository(),
    prefs: SharedPreferencesAsync(),
  );
  await store.load();
  GetIt.I.registerSingleton<AchievementStore>(store);
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('renders summary and badge cards', (tester) async {
    final store = await _registerStore();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle(); // initState refresh settles first
    store.debugSetStats(const AchievementStats(bestStreak: 7, totalDhikr: 100));
    await tester.pumpAndSettle();

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.byType(AchievementCard), findsWidgets);
  });

  testWidgets('unlocked badge shows the unlocked label', (tester) async {
    final store = await _registerStore();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    store.debugSetStats(const AchievementStats(bestStreak: 3));
    await tester.pumpAndSettle();

    expect(find.text('Unlocked'), findsWidgets);
  });

  testWidgets('a badge reads as one node with its progress or status', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final store = await _registerStore();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    store.debugSetStats(const AchievementStats(bestStreak: 3));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp(r', Unlocked$')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r', \d+ / \d+$')), findsWidgets);
    handle.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('badge grid fits at 320dp in Bangla at ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await _registerStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      store.debugSetStats(const AchievementStats(bestStreak: 3));
      await tester.pumpAndSettle();
      // Lay out every card by scrolling through the wall.
      for (var i = 0; i < 40; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(AchievementCard), findsWidgets);
    });
  }

  screenMatrix(
    'AchievementsScreen',
    () => const AchievementsScreen(),
    setUpCase: _registerStore,
    afterPump: (tester) async {
      GetIt.I<AchievementStore>().debugSetStats(
        const AchievementStats(bestStreak: 7, totalDhikr: 100),
      );
      await tester.pumpAndSettle();
    },
  );
}
