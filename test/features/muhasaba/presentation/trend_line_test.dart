import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/muhasaba/presentation/widgets/trend_line.dart';

/// Alpha at the top-left and top-right corners of a [0, 1] trend line —
/// whichever corner is inked is where the latest (100%) day was drawn.
Future<(int, int)> _topCorners(WidgetTester tester, TextDirection dir) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: dir,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(width: 100, child: TrendLine(values: [0, 1])),
          ),
        ),
      ),
    ),
  );
  return (await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    int alphaAt(int x, int y) => bytes.getUint8((y * image.width + x) * 4 + 3);
    final corners = (alphaAt(2, 2), alphaAt(image.width - 3, 2));
    image.dispose();
    return corners;
  }))!;
}

void main() {
  testWidgets('LTR: time runs left → right', (tester) async {
    final (left, right) = await _topCorners(tester, TextDirection.ltr);
    expect(left, 0);
    expect(right, greaterThan(0));
  });

  testWidgets('RTL: mirrored, latest day at the left (end) edge', (
    tester,
  ) async {
    final (left, right) = await _topCorners(tester, TextDirection.rtl);
    expect(left, greaterThan(0));
    expect(right, 0);
  });
}
