import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';

/// Compact tappable pill (design §4) showing the qibla direction with an arrow
/// that rotates to point toward the kaaba relative to the device heading.
/// Purely presentational — [bearing] and [heading] are supplied by the caller.
final class QiblaMiniChip extends StatelessWidget {
  const QiblaMiniChip({
    required this.bearing,
    required this.heading,
    required this.hasLocation,
    this.onTap,
    super.key,
  });

  /// Qibla bearing in degrees (0..360) measured from north, or null.
  final double? bearing;

  /// Device heading in degrees (0..360), or null.
  final double? heading;

  final bool hasLocation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final hasBearing = hasLocation && bearing != null;

    Widget icon;
    if (hasBearing) {
      final angle = (bearing! - (heading ?? 0)) * math.pi / 180;
      icon = Transform.rotate(
        angle: angle,
        child: Icon(Icons.navigation, size: 16, color: q.primary),
      );
    } else {
      icon = Icon(Icons.location_off, size: 16, color: q.ink3);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s3,
          vertical: QSpace.s2,
        ),
        decoration: BoxDecoration(
          color: q.primarySoft,
          borderRadius: BorderRadius.circular(QRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: QSpace.s2),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.qiblaChipLabel,
                  style: QType.caption.copyWith(color: q.ink2),
                ),
                if (hasBearing)
                  Text(
                    LocaleDigits.localize('${bearing!.round()}°', lang),
                    style: QType.num_(QType.caption).copyWith(color: q.ink),
                  )
                else
                  Text(
                    l10n.qiblaChipNeedsLocation,
                    style: QType.caption.copyWith(color: q.ink3),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
