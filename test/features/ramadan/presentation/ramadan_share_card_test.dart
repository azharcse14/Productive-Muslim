import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/features/ramadan/presentation/widgets/ramadan_share_card.dart';

void main() {
  Future<AppLocalizations> pump(
    WidgetTester tester,
    String language, {
    int fastsLogged = 30,
  }) async {
    final date = DateTime(2026, 3, 19);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: RamadanShareCard(
            rozaDay: 30,
            total: 30,
            fastsLogged: fastsLogged,
            hijri: HijriDate.fromGregorian(date),
            date: date,
          ),
        ),
      ),
    );
    return AppLocalizations.delegate.load(Locale(language));
  }

  for (final language in ['en', 'bn']) {
    testWidgets('$language: renders at 4:5 without overflow', (tester) async {
      final l10n = await pump(tester, language);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(RamadanShareCard)),
        RamadanShareCard.size,
      );
      expect(find.text(l10n.ramadanShareBlessing), findsOneWidget);
      // No Material ancestor here either: the card brings its own.
      for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
        expect(text.text.style?.decoration, isNot(TextDecoration.underline));
      }
    });
  }

  testWidgets('bn uses Bangla digits', (tester) async {
    await pump(tester, 'bn');
    expect(find.text('রোজা ৩০/৩০'), findsOneWidget);
    expect(find.text('৩০টি রোজা রেকর্ড হয়েছে'), findsOneWidget);
    expect(find.textContaining('১৪৪৭'), findsWidgets);
  });

  testWidgets('en: shows the fasts line when some are logged', (tester) async {
    final l10n = await pump(tester, 'en');
    expect(find.text(l10n.ramadanShareFastsLogged(30)), findsOneWidget);
    expect(find.text('30 fasts logged'), findsOneWidget);
  });

  testWidgets('no fasts logged: the line is left out, not shown as 0', (
    tester,
  ) async {
    final l10n = await pump(tester, 'en', fastsLogged: 0);
    expect(find.text(l10n.ramadanShareFastsLogged(0)), findsNothing);
    expect(find.text(l10n.ramadanShareFastsLogged(30)), findsNothing);
  });
}
