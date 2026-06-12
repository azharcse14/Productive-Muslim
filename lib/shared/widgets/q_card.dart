import 'package:flutter/widgets.dart';

import '../../core/theme/qalbee_tokens.dart';
import '../extensions/context_ext.dart';

/// Resting card (elevation level e-1): surface, lg radius, hairline border.
final class QCard extends StatelessWidget {
  const QCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tone,
    this.radius = QRadius.lg,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Overrides the surface color (e.g. soft tonal cards).
  final Color? tone;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone ?? q.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: q.line),
        boxShadow: [
          BoxShadow(
            color: q.ink.withValues(alpha: 0.06),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: q.ink.withValues(alpha: 0.07),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
