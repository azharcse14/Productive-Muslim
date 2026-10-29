import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/continue_reading_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('ContinueReadingCard', () {
    testWidgets('renders the title, surah name and ayah label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ContinueReadingCard(
            title: 'Continue reading',
            surahName: 'Al-Baqarah',
            ayahLabel: 'Ayah 152',
          ),
        ),
      );
      expect(find.text('Continue reading'), findsOneWidget);
      expect(find.text('Al-Baqarah'), findsOneWidget);
      expect(find.text('Ayah 152'), findsOneWidget);
    });

    testWidgets('shows a chevron and fires onTap when tappable', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          ContinueReadingCard(
            title: 'Continue reading',
            surahName: 'Al-Baqarah',
            ayahLabel: 'Ayah 152',
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.byType(ContinueReadingCard));
      expect(taps, 1);
    });

    testWidgets('has no chevron when not tappable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ContinueReadingCard(
            title: 'Continue reading',
            surahName: 'Al-Baqarah',
            ayahLabel: 'Ayah 152',
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
