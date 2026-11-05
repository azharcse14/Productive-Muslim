import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/home_header.dart';

void main() {
  testWidgets('date separators are not spoken', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeHeader(
            locationName: 'Dhaka',
            dates: const ['Thu, 5 Nov', '14 Jumada I 1448'],
            onLocationTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('·'), findsOneWidget);
    expect(find.bySemanticsLabel('·'), findsNothing);
    expect(find.bySemanticsLabel('Thu, 5 Nov'), findsOneWidget);
    handle.dispose();
  });
}
