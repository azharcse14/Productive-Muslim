import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';

/// Home card: the "Dua of the day". Purely presentational — the day's dua is
/// selected elsewhere; this widget only displays the passed strings.
final class DuaOfDayCard extends StatelessWidget {
  const DuaOfDayCard({
    required this.arabic,
    required this.translation,
    required this.reference,
    this.onTap,
    super.key,
  });

  final String arabic;
  final String translation;
  final String reference;

  /// Opens the dua collection when set; the card isn't tappable when null.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final card = QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 16,
                color: q.primary,
              ),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  l10n.duaOfDayTitle,
                  style: QType.label.copyWith(color: q.ink2),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: q.ink3),
            ],
          ),
          const SizedBox(height: QSpace.s3),
          Text(
            arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: QType.quran(22).copyWith(color: q.ink),
          ),
          const SizedBox(height: QSpace.s3),
          Text(translation, style: QType.body.copyWith(color: q.ink2)),
          const SizedBox(height: QSpace.s2),
          Text(reference, style: QType.caption.copyWith(color: q.ink3)),
        ],
      ),
    );
    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
