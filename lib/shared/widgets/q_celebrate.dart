import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/utils/haptics.dart';

/// One-shot celebration pulse (slow 420ms: swell to 1.08 and settle) played
/// when [active] flips false → true — a target reached, a day completed.
/// Already-active on first build stays still: we celebrate the moment, not
/// the state. Cut under reduced-motion (the haptic still fires).
final class QCelebrate extends StatefulWidget {
  const QCelebrate({
    required this.active,
    required this.child,
    this.haptic = false,
    super.key,
  });

  final bool active;
  final Widget child;

  /// Fire [Haptics.medium] with the pulse; off where the caller already has
  /// its own milestone haptic.
  final bool haptic;

  @override
  State<QCelebrate> createState() => _QCelebrateState();
}

final class _QCelebrateState extends State<QCelebrate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QMotion.slow,
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.08,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.08,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(QCelebrate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      if (widget.haptic) {
        Haptics.medium();
      }
      if (!MediaQuery.disableAnimationsOf(context)) {
        unawaited(_controller.forward(from: 0));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
