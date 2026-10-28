import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calculators/presentation/screens/fitra_screen.dart';

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FitraScreen(),
    );

void main() {
  group('FitraScreen', () {
    testWidgets('renders title, subtitle and the before-Eid note',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Fitra calculator'), findsOneWidget);
      expect(find.text('Calculate Sadaqatul Fitr for your household'),
          findsOneWidget);
      expect(find.text('Pay before the Eid prayer.'), findsOneWidget);
      // No result before calculating.
      expect(find.textContaining('Per person:'), findsNothing);
    });

    testWidgets('entering values and tapping Calculate shows the result',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();

      // Price per kg field, then people field (default 1).
      final price = find.widgetWithText(TextField, 'Price per kg');
      final people = find.widgetWithText(TextField, 'Number of people');
      await tester.enterText(price, '100');
      await tester.enterText(people, '2');
      await tester.pump();

      await tester.tap(find.text('Calculate'));
      await tester.pump();

      // Wheat default: 1.65 kg * 100 = 165 per person, total 330 for 2.
      expect(find.textContaining('Per person:'), findsOneWidget);
      expect(find.textContaining('Total fitra:'), findsOneWidget);
      expect(find.textContaining('per person'), findsWidgets);

      // Editing an input clears the stale result.
      await tester.enterText(people, '3');
      await tester.pump();
      expect(find.textContaining('Total fitra:'), findsNothing);
    });

    testWidgets('invalid price shows a field error, no result',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Price per kg'),
        'Infinity',
      );
      await tester.tap(find.text('Calculate'));
      await tester.pump();
      expect(find.text('Enter a valid number'), findsOneWidget);
      expect(find.textContaining('Total fitra:'), findsNothing);
    });
  });
}
