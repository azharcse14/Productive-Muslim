import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';

/// Inline informational banner (tonal container + icon + caption text),
/// with an optional visible action button and dismiss (×).
final class QBanner extends StatelessWidget {
  const QBanner({
    required this.text,
    this.icon = Icons.info_outline,
    this.tone,
    this.foreground,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    super.key,
  });

  final String text;
  final IconData icon;

  /// Container color; defaults to primary-soft.
  final Color? tone;

  /// Text/icon color; defaults to on-primary-soft.
  final Color? foreground;

  /// A text button under the message; shown when both are set.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shows a close button that calls this.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final fg = foreground ?? q.onPrimarySoft;
    final action = actionLabel;
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        14,
        12,
        onDismiss == null ? 14 : 0,
        action == null || onAction == null ? 12 : 4,
      ),
      decoration: BoxDecoration(
        color: tone ?? q.primarySoft,
        borderRadius: BorderRadius.circular(QRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: QSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: QType.caption.copyWith(fontSize: 12.5, color: fg),
                ),
                if (action != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: fg,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(action),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: Icon(Icons.close, size: 18, color: fg),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
        ],
      ),
    );
  }
}
