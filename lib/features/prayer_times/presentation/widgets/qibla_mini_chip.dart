import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/kaaba_mark.dart';

/// Compact tappable "glass" pill showing the qibla direction with an arrow
/// that rotates toward the kaaba. Designed to sit in the corner of a tinted
/// hero card: it tints itself with [foreground] over a translucent wash of
/// the same colour, so it reads well on any countdown state.
/// Purely presentational — [bearing]/[heading] are supplied by the caller.
final class QiblaMiniChip extends StatelessWidget {
  const QiblaMiniChip({
    required this.bearing,
    required this.heading,
    required this.hasLocation,
    this.foreground,
    this.onTap,
    super.key,
  });

  /// Qibla bearing in degrees (0..360) measured from north, or null.
  final double? bearing;

  /// Device heading in degrees (0..360), or null.
  final double? heading;

  final bool hasLocation;

  /// Colour for the icon/text and (at low alpha) the pill wash. Defaults to
  /// the primary ink when not supplied.
  final Color? foreground;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? context.q.ink;
    final lang = Localizations.localeOf(context).languageCode;
    final hasBearing = hasLocation && bearing != null;

    final children = <Widget>[];
    if (hasBearing) {
      final angle = (bearing! - (heading ?? 0)) * math.pi / 180;
      children
        ..add(
          // Rotating needle pointing to the qibla, over the kaaba/mecca glyph.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: angle,
                child: Icon(Icons.navigation, size: 13, color: fg),
              ),
              const SizedBox(height: 1.5),
              KaabaMark(size: 11, color: fg.withValues(alpha: 0.9)),
            ],
          ),
        )
        ..add(const SizedBox(width: 5))
        ..add(
          Text(
            LocaleDigits.localize('${bearing!.round()}°', lang),
            style: QType.num_(QType.caption).copyWith(
              fontSize: 11.5,
              color: fg,
              fontVariations: const [FontVariation('wght', 600)],
            ),
          ),
        );
    } else {
      children
        ..add(Icon(Icons.explore_off_outlined, size: 13, color: fg))
        ..add(const SizedBox(width: 5))
        ..add(
          Text(
            context.l10n.qiblaChipLabel,
            style: QType.caption.copyWith(fontSize: 11.5, color: fg),
          ),
        );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(QRadius.full),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
