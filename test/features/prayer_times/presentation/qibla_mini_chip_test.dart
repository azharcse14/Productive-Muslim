import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/prayer_times/presentation/widgets/qibla_mini_chip.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('QiblaMiniChip', () {
    testWidgets('renders label and degrees with location', (tester) async {
      await tester.pumpWidget(_app(
        const QiblaMiniChip(
          bearing: 281,
          heading: 0,
          hasLocation: true,
        ),
      ));
      expect(find.text('Qibla'), findsOneWidget);
      expect(find.text('281°'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsNothing);
    });

    testWidgets('renders needs-location state without location',
        (tester) async {
      await tester.pumpWidget(_app(
        const QiblaMiniChip(
          bearing: null,
          heading: null,
          hasLocation: false,
        ),
      ));
      expect(find.text('Qibla'), findsOneWidget);
      expect(find.text('Set location'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsNothing);
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
