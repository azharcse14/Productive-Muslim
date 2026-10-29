import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../../core/utils/haptics.dart';
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
    final tap = onTap == null
        ? null
        : () {
            Haptics.selection();
            onTap!();
          };
    return Semantics(
      button: onTap != null,
      selected: active,
      label: label,
      onTap: tap,
      child: ExcludeSemantics(
        // The pill stays 36dp; the transparent band around it makes the
        // tap target 48dp.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: QTouch.minTarget),
            child: Center(
              widthFactor: 1,
              child: AnimatedContainer(
                duration: QMotion.fast,
                curve: QMotion.ease,
                constraints: const BoxConstraints(minHeight: 36),
                alignment: Alignment.center,
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
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: QType.label.copyWith(fontSize: 13.5, color: fg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
