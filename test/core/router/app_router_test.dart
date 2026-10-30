import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/router/app_router.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/onboarding/presentation/screens/lock_screen.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';
import 'package:productive_muslim/shared/widgets/q_bottom_nav.dart';

import '../../helpers/content_fakes.dart';
import '../../helpers/home_store_fakes.dart';
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
    final tasbihStore = await makeTasbihStore();
    GetIt.I
      ..registerSingleton<SettingsStore>(settingsStore)
      ..registerSingleton<MosqueStore>(mosqueStore)
      ..registerSingleton<MuhasabaStore>(muhasabaStore)
      ..registerSingleton<AppLockStore>(lockStore)
      ..registerSingleton<QuranStore>(quranStore)
      ..registerSingleton<DuaStore>(duaStore)
      ..registerSingleton<TasbihStore>(tasbihStore)
      // App-wide singleton, as in production (Muhasaba reads it too).
      ..registerLazySingleton<HomeStore>(
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
    testHomeWidgets('boots into the Home branch with 5 nav destinations',
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

    testHomeWidgets('an unknown path lands on Home, not a dead end', (
      tester,
    ) async {
      final router = buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      router.go('/no-such-page');
      await tester.pumpAndSettle();
      expect(find.byType(QBottomNavScaffold), findsOneWidget);
      expect(router.state.uri.path, '/home');
    });

    testHomeWidgets('switching tabs shows the target branch', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quran'));
      await tester.pumpAndSettle();
      // App bar title + nav label.
      expect(find.text('Quran'), findsNWidgets(2));
    });

    testHomeWidgets('tab state persists across switches (indexed stack)',
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

    testHomeWidgets('nav bar hugs the bottom of the screen (regression)',
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

    testHomeWidgets('incomplete setup gates every route to onboarding',
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

    testHomeWidgets('enabled app lock gates to the PIN screen and unlocks',
        (tester) async {
      await GetIt.I.reset();
      final repo = _InMemoryRepo();
      final settingsStore =
          SettingsStore(GetSettings(repo), SaveSettings(repo));
      await settingsStore.load();
      final lockStore = await makeAppLockStore(withPin: true);
      final quranStore = await makeQuranStore();
      final duaStore = await makeDuaStore();
      final tasbihStore = await makeTasbihStore();
      final (mosqueStore, _) = await makeMosqueStore();
      final (muhasabaStore, _) = await makeMuhasabaStore();
      final clock = TimezoneClock();
      GetIt.I
        ..registerSingleton<SettingsStore>(settingsStore)
        ..registerSingleton<AppLockStore>(lockStore)
        ..registerSingleton<QuranStore>(quranStore)
        ..registerSingleton<DuaStore>(duaStore)
        ..registerSingleton<TasbihStore>(tasbihStore)
        ..registerSingleton<MosqueStore>(mosqueStore)
        ..registerSingleton<MuhasabaStore>(muhasabaStore)
        ..registerLazySingleton<HomeStore>(
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

    testHomeWidgets(
        'background re-lock overlays the gate and keeps pushed pages',
        (tester) async {
      await GetIt.I.reset();
      final repo = _InMemoryRepo();
      final settingsStore =
          SettingsStore(GetSettings(repo), SaveSettings(repo));
      await settingsStore.load();
      final lockStore = await makeAppLockStore(withPin: true);
      final (mosqueStore, _) = await makeMosqueStore();
      final (muhasabaStore, _) = await makeMuhasabaStore();
      final clock = TimezoneClock();
      GetIt.I
        ..registerSingleton<SettingsStore>(settingsStore)
        ..registerSingleton<AppLockStore>(lockStore)
        ..registerSingleton<QuranStore>(await makeQuranStore())
        ..registerSingleton<DuaStore>(await makeDuaStore())
        ..registerSingleton<TasbihStore>(await makeTasbihStore())
        ..registerSingleton<MosqueStore>(mosqueStore)
        ..registerSingleton<MuhasabaStore>(muhasabaStore)
        ..registerLazySingleton<HomeStore>(
          () => HomeStore(
            getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
            clock: clock,
            settings: settingsStore,
            mosque: mosqueStore,
          ),
        );
      final router = buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) =>
              LockOverlay(router: router, child: child),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      Future<void> enterPin() async {
        for (final digit in ['1', '2', '3', '4']) {
          await tester.tap(
            find.descendant(
              of: find.byType(LockScreen),
              matching: find.text(digit),
            ),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      // Cold start: the redirect gate.
      expect(router.state.uri.path, '/lock');
      await enterPin();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Calculators'), 200);
      await tester.ensureVisible(find.text('Calculators'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculators'));
      await tester.pumpAndSettle();
      expect(find.text('Zakat calculator'), findsOneWidget);

      // Re-lock (as after the grace period in the background).
      lockStore.locked.value = true;
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsOneWidget);
      expect(router.state.uri.path, isNot('/lock'));
      // The page underneath is still mounted but unreachable.
      await tester.tap(find.text('Zakat calculator'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Cash on hand'), findsNothing);
      // System back is held by the gate, not spent popping hidden pages.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsOneWidget);

      await enterPin();
      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('Zakat calculator'), findsOneWidget);
    });

    // The only test on the global [appRouter] (what openDeepLink drives).
    testHomeWidgets(
        'a notification tap at the cold-start PIN gate opens after unlock '
        'with home beneath', (tester) async {
      GetIt.I
        ..unregister<AppLockStore>()
        ..registerSingleton<AppLockStore>(
          await makeAppLockStore(withPin: true),
        );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      expect(appRouter.state.uri.path, '/lock');

      openDeepLink('/zakat');
      await tester.pumpAndSettle();
      expect(appRouter.state.uri.path, '/lock');
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Cash on hand'), findsOneWidget);
      expect(appRouter.canPop(), isTrue);
      appRouter.pop();
      await tester.pumpAndSettle();
      expect(appRouter.state.uri.path, '/home');
    });

    testHomeWidgets('More opens the Calculators hub with every tool',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      // The Tools group sits below the fold, under the bottom bar.
      await tester.scrollUntilVisible(find.text('Calculators'), 200);
      await tester.ensureVisible(find.text('Calculators'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculators'));
      await tester.pumpAndSettle();
      // Hub lists all five calculators.
      expect(find.text('Zakat calculator'), findsOneWidget);
      expect(find.text('Fitra calculator'), findsOneWidget);
      expect(find.text('Qaza prayer calculator'), findsOneWidget);
      expect(find.text('Inheritance calculator'), findsOneWidget);
      expect(find.text('Age calculator'), findsOneWidget);
    });

    testHomeWidgets('Calculators hub navigates into the Zakat tool',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 1300)); // splash timer
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      // The Tools group sits below the fold, under the bottom bar.
      await tester.scrollUntilVisible(find.text('Calculators'), 200);
      await tester.ensureVisible(find.text('Calculators'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculators'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zakat calculator'));
      await tester.pumpAndSettle();
      // ZakatScreen is now on top — its form fields are present.
      expect(find.text('Cash on hand'), findsOneWidget);
      expect(find.text('Gold (grams)'), findsOneWidget);
    });

    testHomeWidgets('renders Bangla labels under the bn locale', (tester) async {
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
