import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/qibla_mini_chip.dart';
import 'package:productive_muslim/shared/painters/kaaba_mark.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('QiblaMiniChip', () {
    testWidgets('renders the rotating arrow and degrees with location',
        (tester) async {
      await tester.pumpWidget(_app(
        const QiblaMiniChip(
          bearing: 281,
          heading: 0,
          hasLocation: true,
        ),
      ));
      expect(find.text('281°'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
      // Kaaba glyph sits under the rotating needle.
      expect(find.byType(KaabaMark), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_outlined), findsNothing);
    });

    testWidgets('asks for a location + off glyph without location',
        (tester) async {
      await tester.pumpWidget(_app(
        const QiblaMiniChip(
          bearing: null,
          heading: null,
          hasLocation: false,
        ),
      ));
      expect(find.text('Set location'), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsNothing);
    });

    testWidgets('tints icon and text with the given foreground colour',
        (tester) async {
      const fg = Color(0xFF112233);
      await tester.pumpWidget(_app(
        const QiblaMiniChip(
          bearing: 281,
          heading: 0,
          hasLocation: true,
          foreground: fg,
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.navigation));
      expect(icon.color, fg);
    });

    testWidgets('tap fires onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_app(
        QiblaMiniChip(
          bearing: 281,
          heading: 0,
          hasLocation: true,
          onTap: () => tapped++,
        ),
      ));
      await tester.tap(find.byType(QiblaMiniChip));
      expect(tapped, 1);
    });
  });
}
