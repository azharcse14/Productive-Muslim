import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/shared/widgets/staggered_entrance.dart';

void main() {
  group('StaggeredEntrance', () {
    testWidgets('child becomes fully visible after the stagger settles',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: StaggeredEntrance(index: 2, child: Text('hello')),
          ),
        ),
      );
      // The child is in the tree from the first frame (just transparent).
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('hello'), findsOneWidget);
      // Advance past the per-index delay timer so the entrance starts, then
      // let the fade finish.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 1.0);
    });

    testWidgets('reduced motion shows the child immediately at full opacity',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: StaggeredEntrance(index: 5, child: Text('cut')),
          ),
        ),
      );
      // No pumping past any delay: it must already be at its final state.
      await tester.pump();
      expect(find.text('cut'), findsOneWidget);
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 1.0);
    });
  });
}
