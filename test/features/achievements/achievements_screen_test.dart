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
}
