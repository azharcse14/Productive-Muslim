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

    testWidgets('level 0 is surface-2 — neutral, never a shame color',
        (tester) async {
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
      expect(QHeatmapCell.colorFor(ctx, 4), ProductiveMuslimColors.light.primary);
    });
  });
}
