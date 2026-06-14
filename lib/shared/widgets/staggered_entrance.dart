import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/theme/qalbee_tokens.dart';

/// Fades and slides a [child] up into place, with a per-item delay so a list of
/// home-screen cards cascades in on first build. Signature motion is CUT (not
/// animated) under reduced-motion: when [MediaQuery.disableAnimations] is set
/// the child is shown immediately at its final state.
final class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    this.delayStep = const Duration(milliseconds: 60),
    super.key,
  });

  /// Position in the list; multiplies [delayStep] to stagger the entrance.
  final int index;

  /// The widget to animate in.
  final Widget child;

  /// Delay added per [index] before this item starts animating.
  final Duration delayStep;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

final class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QMotion.med,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: QMotion.ease,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      // Reduced motion: cut to the final state, animate nothing.
      _controller.value = 1;
      return;
    }
    // Cap the delay so a long list doesn't take forever to settle.
    final steps = widget.index.clamp(0, 10);
    _timer = Timer(widget.delayStep * steps, () {
      if (mounted) {
        unawaited(_controller.forward());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - _curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
