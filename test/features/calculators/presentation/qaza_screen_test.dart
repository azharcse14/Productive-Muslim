import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calculators/presentation/screens/qaza_screen.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

import '../../../helpers/settings_fakes.dart';

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const QazaScreen(),
);

Future<void> _register(Madhab madhab) async {
  final store = await makeSettingsStore(
    AppSettings(prayerParams: PrayerParams(madhab: madhab)),
  );
  GetIt.I.registerSingleton<SettingsStore>(store);
}

void main() {
  setUp(() => _register(Madhab.hanafi));
  tearDown(GetIt.I.reset);

  group('QazaScreen', () {
    testWidgets('renders the title and calculate button', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Qaza prayer calculator'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('shows the date pickers and the no-guilt note', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('From date'), findsOneWidget);
      expect(find.text('To date'), findsOneWidget);
      // Both date tiles start with the placeholder.
      expect(find.text('Select date'), findsNWidgets(2));
      expect(find.text('Include Witr (Hanafi)'), findsOneWidget);
      expect(find.textContaining('without guilt'), findsOneWidget);
    });

    testWidgets('no result card before calculating', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.textContaining('Total missed:'), findsNothing);
    });

    testWidgets('Witr defaults on for Hanafi, off otherwise', (tester) async {
      bool witr() => tester.widget<Switch>(find.byType(Switch)).value;
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(witr(), isTrue);

      await GetIt.I.reset();
      await _register(Madhab.shafi);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(witr(), isFalse);
    });

    testWidgets('typed input guards back and Clear empties it', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '5');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pump();
      expect(find.text('5'), findsNothing);
    });
  });
}
