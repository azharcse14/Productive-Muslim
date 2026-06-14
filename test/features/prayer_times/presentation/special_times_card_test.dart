import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/prayer_times/domain/entities/special_time.dart';
import 'package:qalbee/features/prayer_times/presentation/widgets/special_times_card.dart';

final _windows = [
  SpecialWindow(
    time: SpecialTime.forbiddenSunrise,
    kind: SpecialKind.forbidden,
    start: DateTime(2026, 6, 12, 5, 10),
    end: DateTime(2026, 6, 12, 5, 25),
  ),
  SpecialWindow(
    time: SpecialTime.forbiddenZawal,
    kind: SpecialKind.forbidden,
    start: DateTime(2026, 6, 12, 11, 54),
    end: DateTime(2026, 6, 12, 12),
  ),
  SpecialWindow(
    time: SpecialTime.ishraq,
    kind: SpecialKind.nafl,
    start: DateTime(2026, 6, 12, 5, 25),
    end: DateTime(2026, 6, 12, 11, 54),
  ),
];

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('SpecialTimesCard', () {
    testWidgets('renders both group titles and window labels',
        (tester) async {
      await tester.pumpWidget(_app(
        SpecialTimesCard(
          windows: _windows,
          active: null,
          formatTime: (t) =>
              '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
        ),
      ));
      expect(find.text('Forbidden times'), findsOneWidget);
      expect(find.text('Nafl times'), findsOneWidget);
      expect(find.text('After sunrise'), findsOneWidget);
      expect(find.text('Midday (zawal)'), findsOneWidget);
      expect(find.text('Ishraq'), findsOneWidget);
      // Time ranges are rendered through the formatter.
      expect(find.text('5:10 – 5:25'), findsOneWidget);
      // Each card carries its explanatory subtitle line.
      expect(
        find.text('No salah may be offered in these three moments.'),
        findsOneWidget,
      );
      expect(
        find.text('Best times for voluntary (nafl) prayers.'),
        findsOneWidget,
      );
    });

    testWidgets('each card opens the detail page for its own kind',
        (tester) async {
      final tapped = <SpecialKind>[];
      await tester.pumpWidget(_app(
        SpecialTimesCard(
          windows: _windows,
          active: null,
          formatTime: (t) => '${t.hour}',
          onTap: tapped.add,
        ),
      ));
      // One chevron per card (forbidden + nafl).
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
      await tester.tap(find.text('Forbidden times'));
      await tester.tap(find.text('Nafl times'));
      expect(tapped, [SpecialKind.forbidden, SpecialKind.nafl]);
    });

    testWidgets('without onTap there is no chevron', (tester) async {
      await tester.pumpWidget(_app(
        SpecialTimesCard(
          windows: _windows,
          active: null,
          formatTime: (t) => '${t.hour}',
        ),
      ));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('shows a Now pill only for the active window', (tester) async {
      await tester.pumpWidget(_app(
        SpecialTimesCard(
          windows: _windows,
          active: SpecialTime.ishraq,
          formatTime: (t) => '${t.hour}',
        ),
      ));
      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('shows no Now pill when nothing is active', (tester) async {
      await tester.pumpWidget(_app(
        SpecialTimesCard(
          windows: _windows,
          active: null,
          formatTime: (t) => '${t.hour}',
        ),
      ));
      expect(find.text('Now'), findsNothing);
    });
  });
}
