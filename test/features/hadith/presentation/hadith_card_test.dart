import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith.dart';
import 'package:productive_muslim/features/hadith/presentation/widgets/hadith_card.dart';
import 'package:productive_muslim/features/hadith/presentation/widgets/hadith_list_card.dart';
import 'package:productive_muslim/shared/extensions/context_ext.dart';
import 'package:productive_muslim/shared/reader/reader_text_size.dart';

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
    expect(isSahihGrade('Munkar Sahih'), isFalse);
    expect(isSahihGrade("Sahih Isnaad, Da'if Matn"), isFalse);
    expect(isSahihGrade('Batil Sahih'), isFalse);
  });

  testWidgets('GradeChip translates every word, punctuation kept', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Column(
            children: [
              GradeChip(grade: 'Sahih - Agreed Upon'),
              GradeChip(grade: 'Shadh, Sahih'),
              GradeChip(grade: 'Mursal Sanad Matn Batil Malool'),
              GradeChip(grade: 'সহিহ হাদিস'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('সহিহ - মুত্তাফাকুন আলাইহি'), findsOneWidget);
    expect(find.text('শায, সহিহ'), findsOneWidget);
    expect(find.text("মুরসাল সনদ মতন বাতিল মা'লুল"), findsOneWidget);
    expect(find.text('সহিহ হাদিস'), findsOneWidget);
  });

  testWidgets("GradeChip warns on Da'if and more strongly on Mawdu", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            GradeChip(grade: 'Sahih'),
            GradeChip(grade: 'Hasan'),
            GradeChip(grade: 'Very Daif'),
            GradeChip(grade: 'দুর্বল হাদিস'),
            GradeChip(grade: 'Mawdu'),
            GradeChip(grade: 'জাল হাদিস'),
          ],
        ),
      ),
    );
    final q = tester
        .element(find.byType(Column).first)
        .q; // the light theme's tokens
    Color colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;
    expect(colorOf('Sahih'), q.ok);
    expect(colorOf('Hasan'), q.ink2);
    expect(colorOf('Very Da\'if'), q.warn);
    expect(colorOf('দুর্বল হাদিস'), q.warn);
    expect(colorOf('Mawdu'), q.urgent);
    expect(colorOf('জাল হাদিস'), q.urgent);
    // Only the four weak / fabricated chips carry the warning icon.
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(4));
  });

  testWidgets('a long grade wraps instead of overflowing (320dp, 1.3x)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            ReaderTextSizeScope(textSize: ReaderTextSize(), child: child!),
        home: const Scaffold(
          body: HadithListCard(
            hadith: Hadith(
              id: 'x',
              topic: 'faith',
              grade: 'Mauquf Hasan Lighairihi',
              arabic: '',
              en: 'Text.',
              bn: 'Text.',
              narrator: '',
              reference: 'Sunan Abi Dawud 1234',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
