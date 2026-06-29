import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';

/// Home card: the "Hadith of the day". Purely presentational — the day's
/// hadith is selected elsewhere; this widget only displays the passed strings.
/// Kept compact: the Arabic text is intentionally not shown here.
final class HadithCard extends StatelessWidget {
  const HadithCard({
    required this.text,
    required this.narrator,
    required this.reference,
    this.onTap,
    super.key,
  });

  final String text;
  final String narrator;
  final String reference;

  /// Opens the full hadith list when set; the card isn't tappable when null.
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
              Icon(Icons.format_quote_outlined, size: 16, color: q.primary),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  l10n.hadithOfDayTitle,
                  style: QType.label.copyWith(color: q.ink2),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: q.ink3),
            ],
          ),
          const SizedBox(height: QSpace.s3),
          Text(
            text,
            style: QType.body.copyWith(color: q.ink),
          ),
          const SizedBox(height: QSpace.s2),
          Text(
            l10n.hadithNarratedBy(narrator),
            style: QType.caption.copyWith(color: q.ink3),
          ),
          Text(
            reference,
            style: QType.caption.copyWith(color: q.ink3),
          ),
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
