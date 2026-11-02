import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';
import 'q_pressable.dart';

/// Inline informational banner (tonal container + icon + caption text).
/// With [onTap] the whole banner is a button with a trailing chevron.
final class QBanner extends StatelessWidget {
  const QBanner({
    required this.text,
    this.icon = Icons.info_outline,
    this.tone,
    this.foreground,
    this.onTap,
    super.key,
  });

  final String text;
  final IconData icon;

  /// Container color; defaults to primary-soft.
  final Color? tone;

  /// Text/icon color; defaults to on-primary-soft.
  final Color? foreground;

  /// Makes the banner tappable: ripple, haptic, chevron, button semantics.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final fg = foreground ?? q.onPrimarySoft;
    final radius = BorderRadius.circular(QRadius.md);
    final decoration = BoxDecoration(
      color: tone ?? q.primarySoft,
      borderRadius: radius,
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s4,
        vertical: QSpace.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: QSpace.s3),
          Expanded(
            child: Text(text, style: QType.captionLg.copyWith(color: fg)),
          ),
          if (onTap != null) ...[
            const SizedBox(width: QSpace.s2),
            Icon(Icons.chevron_right, size: 18, color: fg),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    // Ink paints the fill on the Material, so the ripple shows above it.
    return Semantics(
      button: true,
      child: QPressable(
        onTap: onTap!,
        borderRadius: radius,
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}
