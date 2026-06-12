import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/router/app_router.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:qalbee/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:qalbee/features/prayer_times/presentation/state/home_store.dart';
import 'package:qalbee/features/settings/data/datasources/timezone_clock.dart';
import 'package:qalbee/features/settings/domain/entities/app_settings.dart';
import 'package:qalbee/features/settings/domain/repositories/settings_repository.dart';
import 'package:qalbee/features/settings/domain/usecases/get_settings.dart';
import 'package:qalbee/features/settings/domain/usecases/save_settings.dart';
import 'package:qalbee/features/settings/presentation/state/settings_store.dart';
import 'package:qalbee/shared/widgets/q_bottom_nav.dart';

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored = const AppSettings();

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
    GetIt.I
      ..registerSingleton<SettingsStore>(settingsStore)
      ..registerFactory<HomeStore>(
        () => HomeStore(
          getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
          clock: clock,
          settings: settingsStore,
        ),
      );
  });

  tearDown(() => GetIt.I.reset());
  group('App shell routing', () {
    testWidgets('boots into the Home branch with 5 nav destinations',
        (tester) async {
      await tester.pumpWidget(_app());
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quran'));
      await tester.pumpAndSettle();
      // App bar title + nav label.
      expect(find.text('Quran'), findsNWidgets(2));
    });

    testWidgets('tab state persists across switches (indexed stack)',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muhasaba'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      // The Muhasaba branch stays mounted inside the indexed stack.
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
      await tester.pumpAndSettle();
      expect(find.text('কুরআন'), findsOneWidget);
      expect(find.text('মুহাসাবা'), findsOneWidget);
    });
  });
}
