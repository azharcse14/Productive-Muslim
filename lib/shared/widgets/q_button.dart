import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../../core/utils/haptics.dart';
import '../extensions/context_ext.dart';

enum QButtonKind { primary, tonal, outline, ghost, accent }

/// Pill button per the component library (design §02): five kinds, with
/// pressed (scale .985 + dim), disabled (38% opacity), and focused
/// (double ring) states. Minimum height 52 (40 for [small]).
final class QButton extends StatefulWidget {
  const QButton({
    required this.label,
    required this.onPressed,
    this.kind = QButtonKind.primary,
    this.icon,
    this.small = false,
    this.expand = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final QButtonKind kind;
  final IconData? icon;
  final bool small;
  final bool expand;

  @override
  State<QButton> createState() => _QButtonState();
}

final class _QButtonState extends State<QButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final (Color bg, Color fg, Color border) = switch (widget.kind) {
      QButtonKind.primary => (q.primary, q.onPrimary, Colors.transparent),
      QButtonKind.tonal => (q.primarySoft, q.onPrimarySoft, Colors.transparent),
      QButtonKind.outline => (Colors.transparent, q.primary, q.primary),
      QButtonKind.ghost => (Colors.transparent, q.primary, Colors.transparent),
      QButtonKind.accent => (q.accent, const Color(0xFF231603), Colors.transparent),
    };

    final height = widget.small ? 40.0 : 52.0;
    final child = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: QMotion.fast,
      curve: QMotion.ease,
      child: AnimatedContainer(
        duration: QMotion.fast,
        curve: QMotion.ease,
        constraints: BoxConstraints(minHeight: height),
        padding: EdgeInsets.symmetric(horizontal: widget.small ? 18 : 26),
        decoration: BoxDecoration(
          color: _pressed ? Color.lerp(bg, q.ink, 0.10) : bg,
          borderRadius: BorderRadius.circular(QRadius.full),
          border: Border.all(color: border, width: 1.5),
          boxShadow: _focused
              ? [
                  BoxShadow(color: q.bg, spreadRadius: 3),
                  BoxShadow(color: q.primary, spreadRadius: 5.5),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: widget.small ? 17 : 19, color: fg),
              const SizedBox(width: QSpace.s2),
            ],
            Flexible(
              child: Text(
                widget.label,
                style: QType.titleSm.copyWith(
                  fontSize: widget.small ? 14 : 15.5,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: Opacity(
        opacity: _enabled ? 1 : 0.38,
        child: FocusableActionDetector(
          enabled: _enabled,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: _enabled
                ? () {
                    Haptics.selection();
                    widget.onPressed!();
                  }
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}
