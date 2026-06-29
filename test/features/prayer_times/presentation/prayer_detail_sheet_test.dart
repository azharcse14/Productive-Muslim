import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/prayer_detail_sheet.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('PrayerDetailSheet', () {
    testWidgets('renders the prayer name and the window value', (tester) async {
      await tester.pumpWidget(_app(
        const SingleChildScrollView(
          child: PrayerDetailSheet(
            prayer: Prayer.isha,
            range: '8:10 pm – 4:20 am',
            jamaatTime: '8:30 pm',
          ),
        ),
      ));
      expect(find.text('Isha'), findsOneWidget);
      expect(find.text('Time window'), findsOneWidget);
      expect(find.text('8:10 pm – 4:20 am'), findsOneWidget);
    });

    testWidgets('shows the jamaat value when one is given', (tester) async {
      await tester.pumpWidget(_app(
        const SingleChildScrollView(
          child: PrayerDetailSheet(
            prayer: Prayer.isha,
            range: '8:10 pm – 4:20 am',
            jamaatTime: '8:30 pm',
          ),
        ),
      ));
      expect(find.text('8:30 pm'), findsOneWidget);
      expect(find.text('No jamaat set'), findsNothing);
    });

    testWidgets('shows the no-jamaat fallback when null', (tester) async {
      await tester.pumpWidget(_app(
        const SingleChildScrollView(
          child: PrayerDetailSheet(
            prayer: Prayer.isha,
            range: '8:10 pm – 4:20 am',
          ),
        ),
      ));
      expect(find.text('No jamaat set'), findsOneWidget);
    });

    testWidgets('renders rakaat pills for the prayer', (tester) async {
      await tester.pumpWidget(_app(
        const SingleChildScrollView(
          child: PrayerDetailSheet(
            prayer: Prayer.isha,
            range: '8:10 pm – 4:20 am',
          ),
        ),
      ));
      expect(find.text('4 Fard'), findsOneWidget);
      expect(find.text('2 Sunnah'), findsOneWidget);
      expect(find.text('3 Witr'), findsOneWidget);
    });

    testWidgets('renders the fazilat paragraph', (tester) async {
      await tester.pumpWidget(_app(
        const SingleChildScrollView(
          child: PrayerDetailSheet(
            prayer: Prayer.isha,
            range: '8:10 pm – 4:20 am',
          ),
        ),
      ));
      expect(
        find.textContaining('congregation'),
        findsOneWidget,
      );
    });
  });
}
