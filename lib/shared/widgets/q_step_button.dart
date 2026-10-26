import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/utils/haptics.dart';
import '../extensions/context_ext.dart';

/// Round −/+ stepper button: a small visual circle inside a full
/// [QTouch.minTarget] hit area, so one-thumbed taps don't miss.
final class QStepButton extends StatelessWidget {
  const QStepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.fill,
    this.size = 34,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;

  /// null renders the button disabled.
  final VoidCallback? onTap;

  /// Circle color; defaults to the surface.
  final Color? fill;

  /// Visual diameter (the hit area is always at least 48dp).
  final double size;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                Haptics.selection();
                onTap!();
              },
        child: SizedBox.square(
          dimension: QTouch.minTarget,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill ?? q.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: onTap == null ? q.ink3 : q.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
