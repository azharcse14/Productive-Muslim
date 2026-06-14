import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/shared/widgets/q_chip.dart';
import 'package:qalbee/shared/widgets/q_heatmap.dart';
import 'package:qalbee/shared/widgets/q_list_row.dart';
import 'package:qalbee/shared/widgets/q_seg_control.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('a11y — shared widgets expose semantics', () {
    testWidgets('QChip announces its label, button role and selected state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(QChip(label: 'Asr', active: true, onTap: () {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Asr')),
        isSemantics(isButton: true, isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('QSegControl marks the active segment selected with its label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          QSegControl(
            options: const ['Day', 'Week', 'Month'],
            activeIndex: 1,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Week')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Day')),
        isSemantics(isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('tappable QListRow is a button and merges title + subtitle',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          QListRow(title: 'Madhab', subtitle: 'Hanafi', onTap: () {}),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Madhab')));
      expect(node, isSemantics(isButton: true));
      expect(node.label, contains('Hanafi'));
      handle.dispose();
    });

    testWidgets('QHeatmap surfaces a summary label and hides the raw cells',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const QHeatmap(
            weeks: [
              [0, 1, 2, 3, 4, 0, 1],
            ],
            semanticLabel: '12 of 30 days completed',
          ),
        ),
      );
      // The spoken summary stands in for the whole grid…
      expect(find.bySemanticsLabel('12 of 30 days completed'), findsOneWidget);
      // …and the decorative cells are excluded from the a11y tree.
      final summary =
          tester.getSemantics(find.bySemanticsLabel('12 of 30 days completed'));
      expect(summary.childrenCount, 0);
      handle.dispose();
    });
  });
}
