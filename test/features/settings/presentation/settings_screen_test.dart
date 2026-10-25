import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/screens/settings_screen.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/lock_fakes.dart';

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

/// Tall viewport so the whole (lazy) settings list is laid out at once.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late _InMemoryRepo repo;

  setUp(() async {
    repo = _InMemoryRepo();
    final store = SettingsStore(GetSettings(repo), SaveSettings(repo));
    await store.load();
    final lockStore = await makeAppLockStore();
    GetIt.I
      ..registerSingleton<SettingsStore>(store)
      ..registerSingleton<AppLockStore>(lockStore);
  });

  tearDown(() => GetIt.I.reset());

  group('SettingsScreen', () {
    testWidgets('renders all five groups', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app());
      for (final group in [
        'PRAYER CALCULATION',
        'NOTIFICATIONS',
        'APPEARANCE & LANGUAGE',
        'PRIVACY',
        'ABOUT',
      ]) {
        expect(find.text(group), findsOneWidget, reason: group);
      }
    });

    testWidgets('show achievements switch persists (default off)',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app());
      final row = find.text('Show achievements');
      final toggle = find.descendant(
        of: find.ancestor(of: row, matching: find.byType(Row)).first,
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pump();
      expect(repo.stored.showAchievements, isTrue);
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

    testWidgets('Hijri offset stepper adjusts and clamps at +2',
        (tester) async {
      await tester.pumpWidget(_app());
      final stepper = find.byKey(const ValueKey('hijri-offset-stepper'));
      await tester.scrollUntilVisible(stepper, 100);
      expect(find.text('Match your local moon-sighting'), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      final plus = find.descendant(
        of: stepper,
        matching: find.bySemanticsLabel(RegExp('Increase Hijri date')),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(repo.stored.hijriOffsetDays, 2);
      expect(find.text('+2 days'), findsOneWidget);
      final minus = find.descendant(
        of: stepper,
        matching: find.bySemanticsLabel(RegExp('Decrease Hijri date')),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(minus);
        await tester.pump();
      }
      expect(repo.stored.hijriOffsetDays, -1);
      expect(find.text('−1 day'), findsOneWidget);
    });

    testWidgets('sahri safety stepper adjusts and clamps at 0',
        (tester) async {
      await tester.pumpWidget(_app());
      final stepper = find.byKey(const ValueKey('sahri-safety-stepper'));
      await tester.scrollUntilVisible(stepper, 100);
      expect(find.text('Sahri safety margin'), findsOneWidget);
      Finder button(String verb) => find.descendant(
            of: stepper,
            matching: find.bySemanticsLabel(RegExp('$verb Sahri safety')),
          );
      await tester.tap(button('Decrease'));
      await tester.pump();
      expect(repo.stored.prayerParams.sahriSafetyMinutes, 0);
      for (var i = 0; i < 3; i++) {
        await tester.tap(button('Increase'));
        await tester.pump();
      }
      expect(repo.stored.prayerParams.sahriSafetyMinutes, 3);
    });
  });
}
