import 'package:flutter/material.dart';

import '../../domain/entities/lineage.dart';

/// Draws one timeline-tree row: lines passing through, the line from the
/// parent, the elbows to the children and the row's dot. Columns start on
/// the reading side, so the tree mirrors in RTL.
final class LineagePainter extends CustomPainter {
  const LineagePainter({
    required this.row,
    required this.laneWidth,
    required this.lineColor,
    required this.dotColor,
    required this.textDirection,
  });

  final LineageRow row;
  final double laneWidth;
  final Color lineColor;
  final Color dotColor;
  final TextDirection textDirection;

  static const _dash = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    double x(int column) {
      final fromStart = (column + 0.5) * laneWidth;
      return textDirection == TextDirection.rtl
          ? size.width - fromStart
          : fromStart;
    }

    final mid = size.height / 2;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    void line(Offset a, Offset b, LinkStyle style) {
      if (style == LinkStyle.solid) {
        canvas.drawLine(a, b, paint);
        return;
      }
      final length = (b - a).distance;
      final step = (b - a) / length;
      for (var d = 0.0; d < length; d += _dash * 2) {
        final end = d + _dash < length ? d + _dash : length;
        canvas.drawLine(a + step * d, a + step * end, paint);
      }
    }

    for (final MapEntry(key: column, value: style) in row.through.entries) {
      line(Offset(x(column), 0), Offset(x(column), size.height), style);
    }
    final dot = Offset(x(row.column), mid);
    if (row.incoming case final style?) {
      line(Offset(dot.dx, 0), dot, style);
    }
    for (final MapEntry(key: column, value: style) in row.outgoing.entries) {
      final corner = Offset(x(column), mid);
      if (column != row.column) {
        line(dot, corner, style);
      }
      line(corner, Offset(corner.dx, size.height), style);
    }
    canvas.drawCircle(dot, 6, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(LineagePainter old) =>
      old.row != row ||
      old.laneWidth != laneWidth ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor ||
      old.textDirection != textDirection;
}
