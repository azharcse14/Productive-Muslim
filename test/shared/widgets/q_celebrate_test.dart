import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/shared/widgets/q_celebrate.dart';

Widget _wrap(bool active, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Center(
    child: QCelebrate(
      active: active,
      child: const SizedBox.square(dimension: 10),
    ),
  ),
);

double _scale(WidgetTester tester) =>
    tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;

void main() {
  testWidgets('already active on first build stays still', (tester) async {
    await tester.pumpWidget(_wrap(true));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_scale(tester), 1);
  });

  testWidgets('pulses once when active flips on, then settles', (tester) async {
    await tester.pumpWidget(_wrap(false));
    await tester.pumpWidget(_wrap(true));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_scale(tester), greaterThan(1));
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
  });

  testWidgets('no pulse under reduced motion', (tester) async {
    await tester.pumpWidget(_wrap(false, reduceMotion: true));
    await tester.pumpWidget(_wrap(true, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_scale(tester), 1);
  });
}
