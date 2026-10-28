import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calculators/presentation/screens/inheritance_screen.dart';

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InheritanceScreen(),
    );

/// The form is long; give tests a tall viewport so every field and the
/// Calculate button are laid out (off-screen ListView children aren't built).
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('InheritanceScreen', () {
    testWidgets('renders title, form and disclaimer', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Inheritance calculator'), findsOneWidget);
      expect(find.text('Estate value'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
      expect(
        find.textContaining('Consult a qualified scholar'),
        findsOneWidget,
      );
    });

    testWidgets('wife + son + daughter produces a result breakdown',
        (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pump();

      // Estate.
      await tester.enterText(find.byType(TextField).first, '240000');

      // Select Wife spouse.
      await tester.tap(find.text('Wife'));
      await tester.pumpAndSettle();

      // Bump sons +1 and daughters +1 via the add steppers.
      final adds = find.byIcon(Icons.add_circle_outline);
      // Order of steppers: [wives shown], sons, daughters, brothers, sisters.
      // After selecting Wife, the wife stepper appears first.
      // Sons stepper add is the 2nd add icon, daughters the 3rd.
      await tester.tap(adds.at(1)); // sons
      await tester.pump();
      await tester.tap(adds.at(2)); // daughters
      await tester.pump();

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // Wife row + son + daughter rows should be present.
      expect(find.textContaining('Wife'), findsWidgets);
      expect(find.textContaining('Son'), findsWidgets);
      expect(find.textContaining('Daughter'), findsWidgets);
    });

    testWidgets('husband only shows an unallocated row', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '100000');
      await tester.tap(find.text('Husband'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unallocated'), findsOneWidget);
      expect(find.textContaining('None of the heirs entered'), findsOneWidget);

      // Any input change clears the stale distribution.
      await tester.tap(find.text('Wife'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unallocated'), findsNothing);
    });

    testWidgets('out-of-scope relatives show a banner, no distribution',
        (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '100000');
      await tester.tap(find.text('Husband'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('paternal uncle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      expect(find.textContaining("doesn't cover them"), findsOneWidget);
      expect(find.textContaining('Unallocated'), findsNothing);
    });

    testWidgets('non-numeric estate shows a field error', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'NaN');
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid amount'), findsOneWidget);
    });
  });
}
