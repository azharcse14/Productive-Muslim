import 'package:flutter/widgets.dart';

import '../../../../shared/extensions/context_ext.dart';

/// Minimal trend polyline of day completions (0..1), painted in-house
/// per guide §3.1 — no chart package.
final class TrendLine extends StatelessWidget {
  const TrendLine({
    required this.values,
    this.height = 56,
    this.semanticLabel,
    super.key,
  });

  final List<double> values;
  final double height;

  /// Spoken summary of the trend; the polyline itself carries no meaning to a
  /// screen reader and is excluded from the a11y tree.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final chart = ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrendPainter(
            values: values,
            color: q.primary,
            track: q.line,
          ),
        ),
      ),
    );
    if (semanticLabel == null) {
      return chart;
    }
    return Semantics(label: semanticLabel, child: chart);
  }
}

final class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.track,
  });

  final List<double> values;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = Paint()
      ..strokeWidth = 1
      ..color = track;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      baseline,
    );
    if (values.length < 2) {
      return;
    }
    final path = Path();
    for (final (i, v) in values.indexed) {
      final x = size.width * i / (values.length - 1);
      final y = (1 - v.clamp(0, 1)) * (size.height - 4) + 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      values != oldDelegate.values ||
      color != oldDelegate.color ||
      track != oldDelegate.track;
}
