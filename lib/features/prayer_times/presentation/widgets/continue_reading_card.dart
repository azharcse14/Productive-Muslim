import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';

/// Home card: "Continue reading" — resumes the user's last Quran position
/// (e.g. "Al-Baqarah · Ayah 152"). Purely presentational: every string arrives
/// already localized and digit-formatted; reopening the verse is up to [onTap].
final class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    required this.title,
    required this.surahName,
    required this.ayahLabel,
    this.onTap,
    super.key,
  });

  /// Localized eyebrow, e.g. "Continue reading".
  final String title;

  /// Surah name, e.g. "Al-Baqarah".
  final String surahName;

  /// Already localized + digit-formatted position, e.g. "Ayah 152".
  final String ayahLabel;

  /// Resumes reading when set; the card isn't tappable when null.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final card = QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s5,
        vertical: QSpace.s4,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: q.primarySoft,
              borderRadius: BorderRadius.circular(QRadius.md),
            ),
            child: Icon(Icons.menu_book_outlined, size: 22, color: q.primary),
          ),
          const SizedBox(width: QSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: QType.overline.copyWith(color: q.ink2),
                ),
                const SizedBox(height: 2),
                Text(
                  surahName,
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  ayahLabel,
                  style: QType.caption.copyWith(color: q.ink2),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: QSpace.s2),
            Icon(Icons.chevron_right, size: 20, color: q.ink3),
          ],
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
