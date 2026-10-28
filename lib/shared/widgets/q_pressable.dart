import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/utils/haptics.dart';

/// Tappable surface with the shared press feedback: ink ripple, the same
/// .985 press-scale as QButton, and a selection haptic. The scale follows
/// the InkWell highlight, so a scroll that starts on the surface releases
/// it. Cut (no scale) under reduced-motion.
final class QPressable extends StatefulWidget {
  const QPressable({
    required this.onTap,
    required this.child,
    this.borderRadius,
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<QPressable> createState() => _QPressableState();
}

final class _QPressableState extends State<QPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _pressed && animate ? 0.985 : 1,
      duration: QMotion.fast,
      curve: QMotion.ease,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onTap: () {
            Haptics.selection();
            widget.onTap();
          },
          child: widget.child,
        ),
      ),
    );
  }
}
