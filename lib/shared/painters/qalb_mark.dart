import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The qalb heart path from the design handoff (`HEART_PATH` in base.jsx),
/// in the same 96×96 viewBox as the mark.
Path qalbHeartPath() {
  return Path()
    ..moveTo(48, 62.5)
    ..cubicTo(48, 62.5, 35.7, 55.1, 32.6, 47.7)
    ..cubicTo(30.4, 42.4, 33.5, 37.3, 38.7, 37.3)
    ..cubicTo(42.1, 37.3, 45.1, 39.3, 48, 42.7)
    ..cubicTo(50.9, 39.3, 53.9, 37.3, 57.3, 37.3)
    ..cubicTo(62.5, 37.3, 65.6, 42.4, 63.4, 47.7)
    ..cubicTo(60.3, 55.1, 48, 62.5, 48, 62.5)
    ..close();
}

/// Signature motif: 8-fold star (two interlaced rounded squares) holding
/// the qalb heart. Motif rules: max one treatment per screen; never rotated
/// off-axis; the heart appears only in the full mark, app icon, and the
/// Muhasaba tab icon.
final class QalbMark extends StatelessWidget {
  const QalbMark({
    required this.color,
    this.size = 96,
    this.accent,
    this.strokeWidth = 2.4,
    this.heart = true,
    super.key,
  });

  final double size;
  final Color color;

  /// Heart fill; defaults to [color].
  final Color? accent;
  final double strokeWidth;
  final bool heart;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QalbMarkPainter(
        color: color,
        accent: accent ?? color,
        strokeWidth: strokeWidth,
        heart: heart,
      ),
    );
  }
}

final class _QalbMarkPainter extends CustomPainter {
  const _QalbMarkPainter({
    required this.color,
    required this.accent,
    required this.strokeWidth,
    required this.heart,
  });

  final Color color;
  final Color accent;
  final double strokeWidth;
  final bool heart;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 96;
    canvas.scale(scale);
    paintStar8(canvas, color, strokeWidth);
    if (heart) {
      canvas.drawPath(qalbHeartPath(), Paint()..color = accent);
    }
  }

  /// Two interlaced 54×54 rounded squares (r7) centered at (48,48).
  static void paintStar8(Canvas canvas, Color color, double strokeWidth) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(21, 21, 54, 54),
      const Radius.circular(7),
    );
    canvas.drawRRect(rect, stroke);
    canvas
      ..save()
      ..translate(48, 48)
      ..rotate(math.pi / 4)
      ..translate(-48, -48)
      ..drawRRect(rect, stroke)
      ..restore();
  }

  @override
  bool shouldRepaint(_QalbMarkPainter oldDelegate) =>
      color != oldDelegate.color ||
      accent != oldDelegate.accent ||
      strokeWidth != oldDelegate.strokeWidth ||
      heart != oldDelegate.heart;
}

/// The 8-fold star alone (no heart) — list medallions, small decorations.
final class Star8 extends StatelessWidget {
  const Star8({
    required this.color,
    this.size = 24,
    this.strokeWidth = 6,
    super.key,
  });

  final double size;
  final Color color;

  /// In 96-viewBox units (design uses 6 for small sizes).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _Star8Painter(color: color, strokeWidth: strokeWidth),
    );
  }
}

final class _Star8Painter extends CustomPainter {
  const _Star8Painter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.shortestSide / 96);
    _QalbMarkPainter.paintStar8(canvas, color, strokeWidth);
  }

  @override
  bool shouldRepaint(_Star8Painter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

/// Faint tiling of the motif — the only decorative layer allowed.
/// Background tiling ≤6% opacity, hero cards & splash only.
final class MotifBackground extends StatelessWidget {
  const MotifBackground({
    required this.color,
    this.opacity = 0.05,
    this.cell = 96,
    super.key,
  });

  final Color color;
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _MotifBackgroundPainter(
            color: color.withValues(alpha: opacity),
            cell: cell,
          ),
        ),
      ),
    );
  }
}

final class _MotifBackgroundPainter extends CustomPainter {
  const _MotifBackgroundPainter({required this.color, required this.cell});

  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = color;
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-54, -54, 108, 108),
      const Radius.circular(14),
    );
    for (var x = cell / 2; x < size.width + cell; x += cell) {
      for (var y = cell / 2; y < size.height + cell; y += cell) {
        canvas
          ..save()
          ..translate(x, y)
          ..scale(cell / 240)
          ..drawRRect(rect, stroke)
          ..rotate(math.pi / 4)
          ..drawRRect(rect, stroke)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(_MotifBackgroundPainter oldDelegate) =>
      color != oldDelegate.color || cell != oldDelegate.cell;
}
