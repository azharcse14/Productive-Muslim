import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/special_time.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/special_times_card.dart';

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
  group('SpecialTimeRow', () {
    testWidgets('next forbidden window shows its range and the caveat', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SpecialTimeRow(
            window: _windows[1],
            active: false,
            formatTime: (t) =>
                '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
          ),
        ),
      );
      expect(find.text('Next: Midday (zawal)'), findsOneWidget);
      expect(find.text('11:54\u00A0– 12:00'), findsOneWidget);
      expect(find.textContaining('missed fard'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('active nafl window reads Now, no caveat, opens on tap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          SpecialTimeRow(
            window: _windows[2],
            active: true,
            formatTime: (t) => '${t.hour}',
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('Now: Ishraq'), findsOneWidget);
      expect(find.textContaining('missed fard'), findsNothing);
      await tester.tap(find.byType(SpecialTimeRow));
      expect(taps, 1);
    });
  });
}
