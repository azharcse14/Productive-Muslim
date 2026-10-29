import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../extensions/context_ext.dart';
import 'q_pressable.dart';

/// Resting card (elevation level e-1): surface, lg radius, hairline border.
final class QCard extends StatelessWidget {
  const QCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tone,
    this.radius = QRadius.lg,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Overrides the surface color (e.g. soft tonal cards).
  final Color? tone;
  final double radius;

  /// Makes the whole card tappable: ripple clipped to its shape, press-scale
  /// and haptic via [QPressable].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final decoration = BoxDecoration(
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
    );
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    // Ink paints the surface on the Material, so the ripple shows above it.
    return Semantics(
      button: true,
      child: QPressable(
        onTap: onTap!,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}
