import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../extensions/context_ext.dart';

/// Circular progress ring (dashboard completion, tasbih target, dua repeat).
/// Starts at 12 o'clock, rounded cap, surface-2 track. Fills from empty on
/// first build and eases between values after; cut under reduced-motion.
final class QProgressRing extends StatelessWidget {
  const QProgressRing({
    required this.progress,
    this.size = 120,
    this.strokeWidth = 9,
    this.color,
    this.track,
    this.child,
    super.key,
  });

  /// 0..1, clamped.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : QMotion.med,
        curve: QMotion.ease,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            strokeWidth: strokeWidth,
            color: color ?? q.primary,
            track: track ?? q.surface2,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

final class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.track,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;
    canvas.drawCircle(center, radius, paint);
    if (progress > 0) {
      paint
        ..color = color
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      strokeWidth != oldDelegate.strokeWidth ||
      color != oldDelegate.color ||
      track != oldDelegate.track;
}
