import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/hadith/presentation/widgets/hadith_card.dart';
import 'package:productive_muslim/features/hadith/presentation/widgets/hadith_list_card.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

void main() {
  group('HadithCard', () {
    testWidgets('renders title, text, narrator and reference', (tester) async {
      await tester.pumpWidget(
        _app(
          const HadithCard(
            text: 'Actions are but by intentions.',
            narrator: 'Umar ibn al-Khattab (RA)',
            reference: 'Sahih Bukhari 1',
          ),
        ),
      );

      expect(find.text('Hadith of the day'), findsOneWidget);
      expect(find.text('Actions are but by intentions.'), findsOneWidget);
      expect(find.text('Narrated by Umar ibn al-Khattab (RA)'), findsOneWidget);
      expect(find.text('Sahih Bukhari 1'), findsOneWidget);
    });

    testWidgets('is not tappable and shows no chevron when onTap is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const HadithCard(
            text: 'Cleanliness is half of faith.',
            narrator: 'Abu Malik al-Ash\'ari (RA)',
            reference: 'Sahih Muslim 223',
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('fires onTap and shows a chevron when tappable', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          HadithCard(
            text: 'Fasting is a shield.',
            narrator: 'Abu Hurairah (RA)',
            reference: 'Sahih Bukhari 1894',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byType(HadithCard));
      await tester.pump();

      expect(taps, 1);
    });
  });

  test('isSahihGrade: sahih tone only for plain sahih gradings', () {
    expect(isSahihGrade('Sahih'), isTrue);
    expect(isSahihGrade('Hasan Sahih'), isTrue);
    expect(isSahihGrade('সহিহ হাদিস'), isTrue);
    expect(isSahihGrade('Daif'), isFalse);
    expect(isSahihGrade('দুর্বল হাদিস'), isFalse);
    expect(isSahihGrade('Shadh, Sahih'), isFalse);
    expect(isSahihGrade('সহিহ মওকুফ শায'), isFalse);
  });
}
