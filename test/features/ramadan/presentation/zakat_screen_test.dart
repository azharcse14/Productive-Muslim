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
}
