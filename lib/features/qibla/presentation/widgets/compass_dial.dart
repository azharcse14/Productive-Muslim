import 'dart:math' as math;

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
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DialPainter(
              colors: q,
              heading: heading,
              bearing: bearing,
              aligned: aligned,
              cardinals: cardinals,
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
    );
  }
}

final class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.colors,
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.cardinals,
  });

  final ProductiveMuslimColors colors;
  final double heading;
  final double bearing;
  final bool aligned;
  final List<String> cardinals;

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 300;
    canvas.scale(scale);
    const center = Offset(150, 150);

    // Tick ring + cardinals rotate opposite the device heading so that
    // they stay world-fixed.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(_rad(-heading))
      ..translate(-center.dx, -center.dy);
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
      painter.paint(canvas, Offset(150 - painter.width / 2, 36));
      canvas.restore();
    }
    canvas.restore();

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
    canvas.drawCircle(
      center,
      42,
      Paint()..color = colors.surface,
    );
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
