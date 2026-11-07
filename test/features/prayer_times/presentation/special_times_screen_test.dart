import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/special_time.dart';
import 'package:productive_muslim/features/prayer_times/presentation/screens/special_times_screen.dart';
import '../../../helpers/layout_matrix.dart';

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
    testWidgets('the list clears the system nav bar (edge-to-edge)', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(SpecialKind.forbidden, _forbidden));
      final padding = tester.widget<ListView>(find.byType(ListView)).padding!;
      expect(
        padding.resolve(TextDirection.ltr).bottom,
        20 + 48 / tester.view.devicePixelRatio,
      );
    });

    testWidgets('forbidden page shows only the forbidden intro + windows', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SpecialKind.forbidden, _forbidden));
      await tester.pump();
      expect(find.text('Forbidden times'), findsOneWidget);
      expect(find.textContaining('three moments in the day'), findsOneWidget);
      expect(find.text('After sunrise'), findsOneWidget);
      expect(
        find.textContaining('between the two horns of Shaytan'),
        findsOneWidget,
      );
      // Nothing from the nafl side leaks in.
      expect(find.textContaining('voluntary (nafl) prayers'), findsNothing);
      expect(find.text('Tahajjud'), findsNothing);
    });

    testWidgets('nafl page shows only the nafl intro + windows', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SpecialKind.nafl, _nafl));
      await tester.pump();
      expect(find.text('Nafl times'), findsOneWidget);
      expect(find.textContaining('voluntary (nafl) prayers'), findsOneWidget);
      expect(find.text('Tahajjud'), findsOneWidget);
      expect(find.textContaining('last third of the night'), findsOneWidget);
      expect(find.text('After sunrise'), findsNothing);
    });

    // Regression: on a 402pt iPhone, Bangla zawal's "AM" wrapped alone.
    for (final scale in [1.0, 2.0]) {
      testWidgets('bn zawal range never splits a time (${scale}x)', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(402, 2400)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('bn'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: SpecialTimesScreen(
              kind: SpecialKind.forbidden,
              windows: [
                SpecialWindow(
                  time: SpecialTime.forbiddenZawal,
                  kind: SpecialKind.forbidden,
                  start: DateTime(2026, 6, 12, 11, 33),
                  end: DateTime(2026, 6, 12, 11, 41),
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final range = find.textContaining('–');
        final paragraph = tester.renderObject<RenderParagraph>(range);
        final text = paragraph.text.toPlainText();
        double lineOf(int offset) => paragraph
            .getOffsetForCaret(TextPosition(offset: offset), Rect.zero)
            .dy;
        final dash = text.indexOf('–');
        // Each time sits on one line (the range may break only at the dash).
        expect(lineOf(0), closeTo(lineOf(dash - 1), 4));
        expect(lineOf(dash + 2), closeTo(lineOf(text.length), 4));
        if (scale == 1.0) {
          expect(
            lineOf(0),
            closeTo(lineOf(text.length), 4),
            reason: 'whole range fits',
          );
        }
      });
    }

    testWidgets('renders gracefully with no windows', (tester) async {
      await tester.pumpWidget(_app(SpecialKind.forbidden, const []));
      await tester.pump();
      expect(find.text('Forbidden times'), findsOneWidget);
    });
  });

  for (final kind in SpecialKind.values) {
    layoutMatrix(
      'SpecialTimesScreen ${kind.name}',
      screen: () => SpecialTimesScreen(
        kind: kind,
        windows: kind == SpecialKind.forbidden ? _forbidden : _nafl,
      ),
    );
  }
}
