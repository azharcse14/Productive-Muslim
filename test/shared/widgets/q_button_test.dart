import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/shared/widgets/q_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('QButton', () {
    testWidgets('renders label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(QButton(label: 'Continue', onPressed: () => taps++)),
      );
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(taps, 1);
    });

    testWidgets('disabled button does not fire and dims', (tester) async {
      await tester.pumpWidget(
        _wrap(const QButton(label: 'Disabled', onPressed: null)),
      );
      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Disabled'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.38);
    });

    testWidgets('all five kinds render', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              for (final kind in QButtonKind.values)
                QButton(label: kind.name, kind: kind, onPressed: () {}),
            ],
          ),
        ),
      );
      for (final kind in QButtonKind.values) {
        expect(find.text(kind.name), findsOneWidget);
      }
    });

    testWidgets('exposes button semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(QButton(label: 'Save', onPressed: () {})),
      );
      expect(
        tester.getSemantics(find.byType(QButton)),
        containsSemantics(
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
