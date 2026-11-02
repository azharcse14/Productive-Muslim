import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calculators/presentation/screens/age_screen.dart';
import 'package:productive_muslim/shared/widgets/q_button.dart';

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const AgeScreen(),
);

void main() {
  group('AgeScreen', () {
    testWidgets('renders the title and calculate button', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Age calculator'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('shows the subtitle and date-field labels', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('As of date'), findsOneWidget);
    });

    testWidgets('an as-of date before the birth date blocks Calculate', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      // As of 1 Jan 1990, typed in the picker's input mode.
      await tester.tap(find.text('As of date'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '01/01/1990');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Birth: the picker's default, 1 Jan 2000.
      await tester.tap(find.text('Date of birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('As-of date is before the birth date'), findsOneWidget);
      final button = tester.widget<QButton>(
        find.widgetWithText(QButton, 'Calculate'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
