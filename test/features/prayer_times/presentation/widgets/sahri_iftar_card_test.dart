import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/sahri_iftar_card.dart';

import '../../../../store/store_capture.dart' show loadAppFonts;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('compact times fit a 360dp phone at 2x text', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: SahriIftarCard(
                sahriEnd: '4:52 AM',
                iftar: '5:14 PM',
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('4:52 AM'), findsOneWidget);
    expect(find.text('5:14 PM'), findsOneWidget);
  });
}
