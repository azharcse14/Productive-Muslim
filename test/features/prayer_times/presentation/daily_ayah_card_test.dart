import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/prayer_times/presentation/widgets/daily_ayah_card.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('DailyAyahCard', () {
    testWidgets('renders the title, arabic, and translation', (tester) async {
      await tester.pumpWidget(_app(
        const DailyAyahCard(
          arabic: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ',
          translation: 'Allah - there is no deity except Him.',
          surahName: 'Al-Baqarah',
          ayahNumber: '255',
        ),
      ));
      expect(find.text('Ayah of the day'), findsOneWidget);
      expect(find.text('ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ'), findsOneWidget);
      expect(
        find.text('Allah - there is no deity except Him.'),
        findsOneWidget,
      );
    });

    testWidgets('renders the reference line', (tester) async {
      await tester.pumpWidget(_app(
        const DailyAyahCard(
          arabic: 'ٱللَّهُ',
          translation: 'Allah.',
          surahName: 'Al-Baqarah',
          ayahNumber: '255',
        ),
      ));
      expect(find.text('Al-Baqarah, ayah 255'), findsOneWidget);
    });

    testWidgets('shows a chevron and fires onTap when provided',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(
        DailyAyahCard(
          arabic: 'ٱللَّهُ',
          translation: 'Allah.',
          surahName: 'Al-Baqarah',
          ayahNumber: '255',
          onTap: () => taps++,
        ),
      ));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.byType(DailyAyahCard));
      expect(taps, 1);
    });

    testWidgets('shows no chevron when onTap is null', (tester) async {
      await tester.pumpWidget(_app(
        const DailyAyahCard(
          arabic: 'ٱللَّهُ',
          translation: 'Allah.',
          surahName: 'Al-Baqarah',
          ayahNumber: '255',
        ),
      ));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
