import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/router/app_router.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:qalbee/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:qalbee/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:qalbee/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:qalbee/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:qalbee/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:qalbee/features/prayer_times/presentation/state/home_store.dart';
import 'package:qalbee/features/quran/presentation/state/quran_store.dart';
import 'package:qalbee/features/settings/data/datasources/timezone_clock.dart';
import 'package:qalbee/features/settings/domain/entities/app_settings.dart';
import 'package:qalbee/features/settings/domain/repositories/settings_repository.dart';
import 'package:qalbee/features/settings/domain/usecases/get_settings.dart';
import 'package:qalbee/features/settings/domain/usecases/save_settings.dart';
import 'package:qalbee/features/settings/presentation/state/settings_store.dart';
import 'package:qalbee/shared/widgets/q_bottom_nav.dart';

import '../../helpers/content_fakes.dart';
import '../../helpers/lock_fakes.dart';
import '../../helpers/mosque_fakes.dart';
import '../../helpers/muhasaba_fakes.dart';

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored = const AppSettings(setupComplete: true);

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

Widget _app() => MaterialApp.router(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: buildRouter(),
    );

void main() {
  setUp(() async {
    TimezoneClock.initialize();
    final repo = _InMemoryRepo();
    final settingsStore =
        SettingsStore(GetSettings(repo), SaveSettings(repo));
    await settingsStore.load();
    final clock = TimezoneClock();
    final (mosqueStore, _) = await makeMosqueStore();
    final (muhasabaStore, _) = await makeMuhasabaStore();
    final lockStore = await makeAppLockStore();
    final quranStore = await makeQuranStore();
    final duaStore = await makeDuaStore();
    GetIt.I
      ..registerSingleton<SettingsStore>(settingsStore)
      ..registerSingleton<MosqueStore>(mosqueStore)
      ..registerSingleton<MuhasabaStore>(muhasabaStore)
      ..registerSingleton<AppLockStore>(lockStore)
      ..registerSingleton<QuranStore>(quranStore)
      ..registerSingleton<DuaStore>(duaStore)
      ..registerFactory<HomeStore>(
        () => HomeStore(
          getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
          clock: clock,
          settings: settingsStore,
          mosque: mosqueStore,
        ),
      );
  });

  tearDown(() => GetIt.I.reset());
  group('App shell routing', () {
    testWidgets('boots into the Home branch with 5 nav destinations',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      expect(find.byType(QBottomNavScaffold), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Quran'), findsOneWidget);
      expect(find.text('Muhasaba'), findsOneWidget);
      expect(find.text('Dua'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('switching tabs shows the target branch', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quran'));
      await tester.pumpAndSettle();
      // App bar title + nav label.
      expect(find.text('Quran'), findsNWidgets(2));
    });

    testWidgets('tab state persists across switches (indexed stack)',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muhasaba'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      // The Muhasaba branch stays mounted inside the indexed stack.
      expect(find.text('Muhasaba'), findsOneWidget);
    });

    testWidgets('nav bar hugs the bottom of the screen (regression)',
        (tester) async {
      // A max-sized Column inside the nav once swallowed the whole
      // screen height, centering the bar mid-screen and blanking the
      // body (Scaffold gives the bottomNavigationBar slot loose
      // constraints). Guard the actual geometry.
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      final screen =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      final homeLabel = tester.getCenter(find.text('Home'));
      expect(
        homeLabel.dy,
        greaterThan(screen.height - 120),
        reason: 'nav labels must sit near the bottom edge',
      );
      // And the body above must actually have room.
      expect(find.text('Where are you?'), findsOneWidget);
    });

    testWidgets('incomplete setup gates every route to onboarding',
        (tester) async {
      await GetIt.I.reset();
      final repo = _InMemoryRepo()..stored = const AppSettings();
      final settingsStore =
          SettingsStore(GetSettings(repo), SaveSettings(repo));
      await settingsStore.load();
      final lockStore = await makeAppLockStore();
      final quranStore = await makeQuranStore();
      final duaStore = await makeDuaStore();
      GetIt.I
        ..registerSingleton<SettingsStore>(settingsStore)
        ..registerSingleton<AppLockStore>(lockStore)
        ..registerSingleton<QuranStore>(quranStore)
        ..registerSingleton<DuaStore>(duaStore);
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      expect(find.text('Choose your language'), findsNothing);
      expect(
        find.text('A companion for the heart\'s daily deen'),
        findsOneWidget,
      );
    });

    testWidgets('enabled app lock gates to the PIN screen and unlocks',
        (tester) async {
      await GetIt.I.reset();
      final repo = _InMemoryRepo();
      final settingsStore =
          SettingsStore(GetSettings(repo), SaveSettings(repo));
      await settingsStore.load();
      final lockStore = await makeAppLockStore(withPin: true);
      final quranStore = await makeQuranStore();
      final duaStore = await makeDuaStore();
      final (mosqueStore, _) = await makeMosqueStore();
      final (muhasabaStore, _) = await makeMuhasabaStore();
      final clock = TimezoneClock();
      GetIt.I
        ..registerSingleton<SettingsStore>(settingsStore)
        ..registerSingleton<AppLockStore>(lockStore)
        ..registerSingleton<QuranStore>(quranStore)
        ..registerSingleton<DuaStore>(duaStore)
        ..registerSingleton<MosqueStore>(mosqueStore)
        ..registerSingleton<MuhasabaStore>(muhasabaStore)
        ..registerFactory<HomeStore>(
          () => HomeStore(
            getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
            clock: clock,
            settings: settingsStore,
            mosque: mosqueStore,
          ),
        );
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      expect(find.text('Enter your PIN'), findsOneWidget);
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      // Unlocked → router refresh lands on the shell.
      expect(find.text('Muhasaba'), findsOneWidget);
    });

    testWidgets('renders Bangla labels under the bn locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: buildRouter(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      expect(find.text('কুরআন'), findsOneWidget);
      expect(find.text('মুহাসাবা'), findsOneWidget);
    });
  });
}
