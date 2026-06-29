import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/special_time.dart';
import 'package:productive_muslim/features/prayer_times/presentation/screens/special_times_screen.dart';

final _forbidden = [
  SpecialWindow(
    time: SpecialTime.forbiddenSunrise,
    kind: SpecialKind.forbidden,
    start: DateTime(2026, 6, 12, 5, 10),
    end: DateTime(2026, 6, 12, 5, 25),
  ),
];

final _nafl = [
  SpecialWindow(
    time: SpecialTime.tahajjud,
    kind: SpecialKind.nafl,
    start: DateTime(2026, 6, 13, 2),
    end: DateTime(2026, 6, 13, 3, 44),
  ),
];

Widget _app(SpecialKind kind, List<SpecialWindow> windows) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SpecialTimesScreen(kind: kind, windows: windows),
    );

void main() {
  group('SpecialTimesScreen', () {
    testWidgets('forbidden page shows only the forbidden intro + windows',
        (tester) async {
      await tester.pumpWidget(_app(SpecialKind.forbidden, _forbidden));
      await tester.pump();
      expect(find.text('Forbidden times'), findsOneWidget);
      expect(find.textContaining('three moments in the day'), findsOneWidget);
      expect(find.text('After sunrise'), findsOneWidget);
      expect(find.textContaining('between the two horns of Shaytan'),
          findsOneWidget);
      // Nothing from the nafl side leaks in.
      expect(find.textContaining('voluntary (nafl) prayers'), findsNothing);
      expect(find.text('Tahajjud'), findsNothing);
    });

    testWidgets('nafl page shows only the nafl intro + windows',
        (tester) async {
      await tester.pumpWidget(_app(SpecialKind.nafl, _nafl));
      await tester.pump();
      expect(find.text('Nafl times'), findsOneWidget);
      expect(find.textContaining('voluntary (nafl) prayers'), findsOneWidget);
      expect(find.text('Tahajjud'), findsOneWidget);
      expect(find.textContaining('last third of the night'), findsOneWidget);
      expect(find.text('After sunrise'), findsNothing);
    });

    testWidgets('renders gracefully with no windows', (tester) async {
      await tester.pumpWidget(_app(SpecialKind.forbidden, const []));
      await tester.pump();
      expect(find.text('Forbidden times'), findsOneWidget);
    });
  });
}
