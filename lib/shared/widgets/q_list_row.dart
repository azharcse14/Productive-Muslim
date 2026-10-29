import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';
import 'q_pressable.dart';

/// Standard list row: tonal icon tile, title + optional subtitle, trailing
/// widget. Minimum height 56 (touch-target safe). [selected] marks a chosen
/// option for screen readers (pair it with a visible check).
final class QListRow extends StatelessWidget {
  const QListRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconTone,
    this.trailing,
    this.onTap,
    this.selected,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconTone;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 2,
          vertical: 10,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconTone ?? q.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: q.onPrimarySoft),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: QType.titleSm.copyWith(color: q.ink)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        subtitle!,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
    if (onTap == null) {
      return MergeSemantics(
        child: Semantics(selected: selected, child: row),
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: selected != null,
        child: QPressable(
          onTap: onTap!,
          borderRadius: BorderRadius.circular(QRadius.md),
          child: row,
        ),
      ),
    );
  }
}
