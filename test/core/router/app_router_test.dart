import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/router/app_router.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/shared/widgets/q_bottom_nav.dart';

Widget _app() => MaterialApp.router(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: buildRouter(),
    );

void main() {
  group('App shell routing', () {
    testWidgets('boots into the Home branch with 5 nav destinations',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.byType(QBottomNavScaffold), findsOneWidget);
      // Tab labels in the nav bar (Home appears in app bar too).
      expect(find.text('Home'), findsNWidgets(2));
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
      await tester.tap(find.text('Home').last);
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
