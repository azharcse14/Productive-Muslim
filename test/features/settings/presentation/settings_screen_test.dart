import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/settings/domain/entities/app_settings.dart';
import 'package:qalbee/features/settings/domain/repositories/settings_repository.dart';
import 'package:qalbee/features/settings/domain/usecases/get_settings.dart';
import 'package:qalbee/features/settings/domain/usecases/save_settings.dart';
import 'package:qalbee/features/settings/presentation/screens/settings_screen.dart';
import 'package:qalbee/features/settings/presentation/state/settings_store.dart';

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

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );

void main() {
  late _InMemoryRepo repo;

  setUp(() async {
    repo = _InMemoryRepo();
    final store = SettingsStore(GetSettings(repo), SaveSettings(repo));
    await store.load();
    GetIt.I.registerSingleton<SettingsStore>(store);
  });

  tearDown(() => GetIt.I.reset());

  group('SettingsScreen', () {
    testWidgets('renders all five groups', (tester) async {
      await tester.pumpWidget(_app());
      expect(find.text('PRAYER CALCULATION'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('APPEARANCE & LANGUAGE'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('PRIVACY'), 200);
      expect(find.text('PRIVACY'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('ABOUT'), 200);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('location row shows "Not set" before setup', (tester) async {
      await tester.pumpWidget(_app());
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('madhab sheet selection persists', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Madhab (Asr)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shafiʿi'));
      await tester.pumpAndSettle();
      expect(repo.stored.prayerParams.madhab.name, 'shafi');
      expect(find.text('Shafiʿi'), findsOneWidget); // now the subtitle
    });

    testWidgets('theme sheet selection persists', (tester) async {
      await tester.pumpWidget(_app());
      await tester.scrollUntilVisible(find.text('Theme'), 200);
      await tester.ensureVisible(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(repo.stored.themeMode, AppThemeMode.dark);
    });

    testWidgets('credits mention required attributions', (tester) async {
      await tester.pumpWidget(_app());
      await tester.scrollUntilVisible(
        find.textContaining('GeoNames'),
        200,
      );
      expect(find.textContaining('KFGQPC'), findsOneWidget);
    });
  });
}
