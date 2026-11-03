import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calculators/presentation/screens/age_screen.dart';

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

    testWidgets('as-of date cannot be picked before the birth date', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      // Birth: the picker's default, 1 Jan 2000.
      await tester.tap(find.text('Date of birth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('As of date'));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(2000));
    });

    testWidgets('birth date cannot be picked after the as-of date', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.text('Date of birth'));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      final now = DateTime.now();
      expect(picker.lastDate, DateTime(now.year, now.month, now.day));
    });
  });
}
