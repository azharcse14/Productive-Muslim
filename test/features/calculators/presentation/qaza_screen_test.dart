import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calculators/presentation/screens/qaza_screen.dart';

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const QazaScreen(),
    );

void main() {
  group('QazaScreen', () {
    testWidgets('renders the title and calculate button', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Qaza prayer calculator'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('shows the date pickers and the no-guilt note', (tester) async {
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
  });
}
