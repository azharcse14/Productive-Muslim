import 'package:flutter/material.dart';

import '../../core/theme/qalbee_tokens.dart';
import '../../core/theme/qalbee_typography.dart';
import '../extensions/context_ext.dart';

/// Inline informational banner (tonal container + icon + caption text).
final class QBanner extends StatelessWidget {
  const QBanner({
    required this.text,
    this.icon = Icons.info_outline,
    this.tone,
    this.foreground,
    super.key,
  });

  final String text;
  final IconData icon;

  /// Container color; defaults to primary-soft.
  final Color? tone;

  /// Text/icon color; defaults to on-primary-soft.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final fg = foreground ?? q.onPrimarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            child: Text(
              text,
              style: QType.caption.copyWith(fontSize: 12.5, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
