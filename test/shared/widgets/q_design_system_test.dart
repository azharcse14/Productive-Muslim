import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/shared/widgets/q_banner.dart';
import 'package:productive_muslim/shared/widgets/q_medallion.dart';
import 'package:productive_muslim/shared/widgets/q_number_dialog.dart';
import 'package:productive_muslim/shared/widgets/q_section_header.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('QBanner', () {
    testWidgets('static banner has no chevron and no button role', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const QBanner(text: 'Info')));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('onTap adds a chevron, button semantics and fires', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _wrap(QBanner(text: 'Fix it', onTap: () => taps++)),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Fix it')),
        isSemantics(isButton: true, hasTapAction: true, label: 'Fix it'),
      );
      await tester.tap(find.text('Fix it'));
      expect(taps, 1);
      handle.dispose();
    });
  });

  testWidgets('QSectionHeader is an uppercase header', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const QSectionHeader('Tools')));
    expect(find.text('TOOLS'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('TOOLS')),
      isSemantics(isHeader: true, label: 'TOOLS'),
    );
    handle.dispose();
  });

  testWidgets('number dialog shows the range on an out-of-range entry', (
    tester,
  ) async {
    int? result = -1;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showNumberDialog(
              context,
              title: 'Target',
              hint: 'How many?',
              actionLabel: 'Save',
              max: 99,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter 1–99'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '42');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 42);
  });

  testWidgets('QMedallion number fits inside the star at 2x text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const QMedallion(number: 286, size: 34), textScale: 2),
    );
    expect(tester.takeException(), isNull);
    final star = tester.getRect(find.byType(QMedallion));
    final text = tester.getRect(find.text('286'));
    expect(star.contains(text.topLeft), isTrue);
    expect(star.contains(text.bottomRight), isTrue);
  });
}
