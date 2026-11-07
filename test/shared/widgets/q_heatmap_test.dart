import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/theme/productive_muslim_colors.dart';
import 'package:productive_muslim/shared/widgets/q_heatmap.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('QHeatmap', () {
    testWidgets('renders a cell per level entry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QHeatmap(
            weeks: [
              [0, 1, 2, 3, 4, 0, 1],
              [2, 3, 4, 0, 1, 2, -1],
            ],
          ),
        ),
      );
      expect(find.byType(QHeatmapCell), findsNWidgets(14));
    });

    testWidgets('maxCellSize: short grid grows and centers, long one scrolls', (
      tester,
    ) async {
      List<List<int>> weeks(int n) => [
        for (var i = 0; i < n; i++) [0, 1, 2, 3, 4, 0, 1],
      ];
      Widget at(int n) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 300,
              child: QHeatmap(weeks: weeks(n), maxCellSize: 28),
            ),
          ),
        ),
      );
      final cells = find.byType(QHeatmapCell);

      await tester.pumpWidget(at(2));
      expect(tester.widget<QHeatmapCell>(cells.first).size, 28);
      final mid =
          (tester.getTopLeft(cells.first).dx +
              tester.getTopRight(cells.last).dx) /
          2;
      expect(mid, moreOrLessEquals(150, epsilon: 0.5));

      await tester.pumpWidget(at(53));
      expect(tester.widget<QHeatmapCell>(cells.first).size, 13);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap on a grown cell picks that cell', (tester) async {
      (int, int)? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 300,
                child: QHeatmap(
                  weeks: const [
                    [1, 1, 1, 1, 1, 1, 1],
                    [1, 1, 1, 1, 1, 1, 1],
                  ],
                  maxCellSize: 28,
                  onTap: (w, d) => tapped = (w, d),
                ),
              ),
            ),
          ),
        ),
      );
      // Last cell of the second week: (1, 6).
      await tester.tap(find.byType(QHeatmapCell).last);
      expect(tapped, (1, 6));
    });

    testWidgets('level 0 is surface-2 — neutral, never a shame color', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              ctx = context;
              return const QHeatmapCell(level: 0);
            },
          ),
        ),
      );
      expect(
        QHeatmapCell.colorFor(ctx, 0),
        ProductiveMuslimColors.light.surface2,
      );
      expect(
        QHeatmapCell.colorFor(ctx, 0),
        isNot(ProductiveMuslimColors.light.urgent),
      );
    });

    testWidgets('level 4 is full primary', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              ctx = context;
              return const QHeatmapCell(level: 4);
            },
          ),
        ),
      );
      expect(
        QHeatmapCell.colorFor(ctx, 4),
        ProductiveMuslimColors.light.primary,
      );
    });

    testWidgets('a tap in a gap picks the nearest cell; cells keep labels', (
      tester,
    ) async {
      final taps = <(int, int)>[];
      await tester.pumpWidget(
        _wrap(
          QHeatmap(
            weeks: const [
              [0, 1, 2, 3, 4, 0, 1],
              [2, 3, 4, 0, 1, 2, -1],
            ],
            onTap: (w, d) => taps.add((w, d)),
            cellLabel: (w, d) => 'cell $w $d',
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(QHeatmap));
      // Pitch is 13 + 3.5. Just past cell (0, 0) into the gap on its right
      // and below: still (0, 0). Just before cell (1, 1): (1, 1).
      await tester.tapAt(origin + const Offset(14.5, 14.5));
      await tester.tapAt(origin + const Offset(15.5, 15.5));
      // Out-of-range cell (1, 6) stays inert.
      await tester.tapAt(origin + const Offset(20, 6 * 16.5 + 5));
      expect(taps, [(0, 0), (1, 1)]);

      expect(find.bySemanticsLabel('cell 1 3'), findsOneWidget);
    });

    testWidgets('gap taps map to the mirrored column under RTL', (
      tester,
    ) async {
      final taps = <(int, int)>[];
      await tester.pumpWidget(
        _wrap(
          Directionality(
            textDirection: TextDirection.rtl,
            child: QHeatmap(
              weeks: const [
                [0, 0],
                [0, 0],
              ],
              onTap: (w, d) => taps.add((w, d)),
            ),
          ),
        ),
      );
      // Week 0 is drawn on the right under RTL.
      final topRight = tester.getTopRight(find.byType(QHeatmap));
      await tester.tapAt(topRight + const Offset(-14.5, 2));
      expect(taps, [(0, 0)]);
    });
  });
}
