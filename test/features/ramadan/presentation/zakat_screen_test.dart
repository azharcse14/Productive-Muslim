import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/ramadan/presentation/screens/zakat_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) {
    // Tall enough that the whole form and result fit without scrolling.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ZakatScreen(),
      ),
    );
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> calculate(WidgetTester tester) async {
    await tester.tap(find.text('Calculate'));
    await tester.pump();
  }

  testWidgets('gold grams without a gold price is a field error, no result', (
    tester,
  ) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatSilverPrice), '1');
    await tester.enterText(field(l10n.zakatGold), '100');
    await calculate(tester);

    // Field error + banner.
    expect(find.text(l10n.zakatNeedMetalPrice), findsNWidgets(2));
    expect(find.text(l10n.zakatNotPayable), findsNothing);
  });

  testWidgets('pricing every held metal yields a result', (tester) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatGoldPrice), '100');
    await tester.enterText(field(l10n.zakatSilverPrice), '1');
    await tester.enterText(field(l10n.zakatGold), '100');
    await calculate(tester);

    expect(find.text(l10n.zakatNeedMetalPrice), findsNothing);
    expect(find.textContaining('Zakat due'), findsOneWidget);
  });

  testWidgets('unparseable text is a field error', (tester) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatSilverPrice), '1');
    await tester.enterText(field(l10n.zakatCash), '1.2.3');
    await tester.enterText(field(l10n.zakatBank), '.');
    await calculate(tester);

    expect(find.text(l10n.zakatInvalidNumber), findsNWidgets(2));
    expect(find.textContaining('Zakat due'), findsNothing);
  });

  testWidgets('cash without a silver price flags the silver price field', (
    tester,
  ) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatGoldPrice), '100');
    await tester.enterText(field(l10n.zakatCash), '100000');
    await calculate(tester);

    // Silver price field error + banner, no gold-nisab fallback.
    expect(find.text(l10n.zakatNeedSilverPrice), findsNWidgets(2));
    expect(find.textContaining('Zakat due'), findsNothing);
  });

  testWidgets('gold alone needs only the gold price', (tester) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatGoldPrice), '100');
    await tester.enterText(field(l10n.zakatGold), '100');
    await calculate(tester);

    expect(find.text(l10n.zakatNeedSilverPrice), findsNothing);
    expect(find.textContaining('Zakat due'), findsOneWidget);
  });

  testWidgets('amount fields reject signs and letters, keep bn digits', (
    tester,
  ) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatCash), '-5x০0');
    await tester.enterText(field(l10n.zakatBank), 'NaN');

    expect(
      tester.widget<TextField>(field(l10n.zakatCash)).controller!.text,
      '5০0',
    );
    expect(
      tester.widget<TextField>(field(l10n.zakatBank)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('result names the nisab used and clears on edit', (tester) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.enterText(field(l10n.zakatGoldPrice), '100');
    await tester.enterText(field(l10n.zakatGold), '100');
    await calculate(tester);

    expect(find.text('Gold nisab (87.48 g)'), findsOneWidget);
    expect(find.text(l10n.zakatRowMetals), findsOneWidget);

    await tester.enterText(field(l10n.zakatGold), '50');
    await tester.pump();
    expect(find.textContaining('Zakat due'), findsNothing);
    expect(find.text('Gold nisab (87.48 g)'), findsNothing);
  });
}
