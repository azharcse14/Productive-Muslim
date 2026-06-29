import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';

/// Selectable pill chip (filters, presets).
final class QChip extends StatelessWidget {
  const QChip({
    required this.label,
    this.active = false,
    this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final fg = active ? q.onPrimary : q.ink2;
    return Semantics(
      button: onTap != null,
      selected: active,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: QMotion.fast,
            curve: QMotion.ease,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: active ? q.primary : q.surface,
              borderRadius: BorderRadius.circular(QRadius.full),
              border: Border.all(
                color: active ? q.primary : q.line,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: QType.label.copyWith(fontSize: 13.5, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
