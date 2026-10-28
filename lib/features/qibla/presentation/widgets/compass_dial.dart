import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../../../core/theme/productive_muslim_colors.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';

/// The qibla dial (design §06, ui.jsx CompassDial): tick ring + cardinal
/// labels rotating with −heading, fixed alignment arc at the top, needle
/// at (bearing − heading), center medallion with the qalb mark. Gold
/// accent everywhere when aligned.
final class CompassDial extends StatelessWidget {
  const CompassDial({
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.cardinals,
    this.size = 300,
    super.key,
  });

  /// Smoothed true heading (declination-corrected), degrees.
  final double heading;

  /// Qibla bearing from north, degrees.
  final double bearing;
  final bool aligned;

  /// Localized N/E/S/W labels in order.
  final List<String> cardinals;
  final double size;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    // Own layer so per-event repaints stay inside the dial, not the route.
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tick ring + cardinals rotate opposite the device heading so that
            // they stay world-fixed. Painted once and cached; each sensor
            // event only re-composites the rotation.
            Transform.rotate(
              angle: _rad(-heading),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(colors: q, cardinals: cardinals),
                ),
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _DialPainter(
                colors: q,
                heading: heading,
                bearing: bearing,
                aligned: aligned,
              ),
            ),
            QalbMark(
              size: size * 40 / 300,
              color: aligned ? q.accent : q.primary,
              accent: aligned ? q.accent : q.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

double _rad(double deg) => deg * math.pi / 180;

/// Maps the 300×300 design space onto [size], centered, so the painted
/// center matches the Stack/Transform center even when the box isn't square.
void _fitDesign(Canvas canvas, Size size) {
  canvas
    ..translate(size.width / 2, size.height / 2)
    ..scale(size.shortestSide / 300)
    ..translate(-150, -150);
}

/// The world-fixed tick ring and cardinal labels, unrotated (north up).
final class _RingPainter extends CustomPainter {
  const _RingPainter({required this.colors, required this.cardinals});

  final ProductiveMuslimColors colors;
  final List<String> cardinals;

  @override
  void paint(Canvas canvas, Size size) {
    _fitDesign(canvas, size);
    const center = Offset(150, 150);
    for (var a = 0; a < 360; a += 6) {
      final major = a % 90 == 0;
      final mid = a % 30 == 0;
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = mid ? 2.5 : 1.4
        ..color = major ? colors.ink2 : colors.line;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(_rad(a.toDouble()))
        ..translate(-center.dx, -center.dy)
        ..drawLine(
          const Offset(150, 14),
          Offset(150, major ? 30 : (mid ? 26 : 21)),
          paint,
        )
        ..restore();
    }
    for (final (i, label) in cardinals.indexed) {
      final angle = i * 90.0;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(_rad(angle))
        ..translate(-center.dx, -center.dy);
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: i == 0 ? colors.urgent : colors.ink3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter
        ..paint(canvas, Offset(150 - painter.width / 2, 36))
        ..dispose();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      colors != oldDelegate.colors ||
      !listEquals(cardinals, oldDelegate.cardinals);
}

/// Alignment arc, needle and center medallion: cheap, repainted per event.
final class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.colors,
    required this.heading,
    required this.bearing,
    required this.aligned,
  });

  final ProductiveMuslimColors colors;
  final double heading;
  final double bearing;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    _fitDesign(canvas, size);
    const center = Offset(150, 150);

    // Fixed alignment arc at 12 o'clock.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = aligned ? colors.accent : colors.line;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 135),
      _rad(-90 - 7.6),
      _rad(15.2),
      false,
      arcPaint,
    );

    // Needle points at the qibla relative to the device's current heading.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(_rad(bearing - heading))
      ..translate(-center.dx, -center.dy);
    final needle = Path()
      ..moveTo(150, 58)
      ..lineTo(162, 150)
      ..lineTo(150, 138)
      ..lineTo(138, 150)
      ..close();
    canvas
      ..drawPath(
        needle,
        Paint()..color = aligned ? colors.accent : colors.primary,
      )
      ..drawLine(
        const Offset(150, 150),
        const Offset(150, 206),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = colors.line,
      )
      ..restore();

    // Center medallion (the qalb mark widget sits on top).
    canvas.drawCircle(center, 42, Paint()..color = colors.surface);
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = colors.line,
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      heading != oldDelegate.heading ||
      bearing != oldDelegate.bearing ||
      aligned != oldDelegate.aligned ||
      colors != oldDelegate.colors;
}
