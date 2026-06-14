import 'package:flutter/widgets.dart';

/// A tiny, single-colour Kaaba glyph (the cube in Makkah) for the qibla
/// indicator — Material has no kaaba icon. Drawn as a filled cube with the
/// kiswa band (hizam) and the door carved out (even-odd), so the cut-outs
/// show whatever sits behind the mark.
final class KaabaMark extends StatelessWidget {
  const KaabaMark({required this.color, this.size = 16, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _KaabaPainter(color),
      );
}

class _KaabaPainter extends CustomPainter {
  _KaabaPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Rect r(double l, double t, double right, double b) =>
        Rect.fromLTRB(l * w, t * h, right * w, b * h);

    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(r(0.17, 0.11, 0.83, 0.92), Radius.circular(0.05 * w)),
      );
    // Kiswa band across the upper third, and the door at the base.
    final cuts = Path()
      ..addRect(r(0.17, 0.30, 0.83, 0.38))
      ..addRect(r(0.55, 0.60, 0.71, 0.92));
    final glyph = Path.combine(PathOperation.difference, body, cuts);

    canvas.drawPath(
      glyph,
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_KaabaPainter old) => old.color != color;
}
