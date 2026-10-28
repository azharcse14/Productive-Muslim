import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/shared/widgets/q_card.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _scale(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  testWidgets('tappable QCard shrinks while pressed and fires onTap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(QCard(onTap: () => taps++, child: const Text('Card'))),
    );
    expect(_scale(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Card')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 0.985);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
    expect(taps, 1);
  });

  testWidgets('no press-scale under reduced motion', (tester) async {
    await tester.pumpWidget(
      _wrap(QCard(onTap: () {}, child: const Text('Card')), reduceMotion: true),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Card')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 1);
    await gesture.up();
  });
}
