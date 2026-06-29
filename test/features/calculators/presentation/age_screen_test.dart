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
  });
}
