import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_progress_ring.dart';

/// Minimal home summary of today's muhasaba track (design §4.3 hand-off
/// to §4.7): completion ring + done/total count, with a compact streak,
/// tappable into the dashboard.
final class HomeMuhasabaCard extends StatelessWidget {
  const HomeMuhasabaCard({
    super.key,
    required this.completion,
    required this.doneToday,
    required this.totalItems,
    required this.streak,
    required this.onTap,
    this.milestone = false,
  });

  /// Today's completion across active items, 0..1.
  final double completion;

  /// Items completed today and the active-item total (the "3/8 done" line).
  final int doneToday;
  final int totalItems;
  final int streak;
  final VoidCallback onTap;

  /// The streak just hit a celebratory length — show a small accent badge.
  final bool milestone;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: QCard(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s5,
          vertical: QSpace.s4,
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: completion),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : QMotion.slow,
              curve: QMotion.ease,
              builder: (context, value, _) => QProgressRing(
                progress: value,
                size: 44,
                strokeWidth: 5,
                child: Text(
                  LocaleDigits.localize(
                    '${(completion * 100).round()}%',
                    languageCode,
                  ),
                  style: QType.num_(
                    QType.caption,
                  ).copyWith(fontSize: 11, color: q.ink),
                ),
              ),
            ),
            const SizedBox(width: QSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.muhasabaTitle,
                    style: QType.titleSm.copyWith(color: q.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleDigits.localize(
                      l10n.muhasabaDoneCount(doneToday, totalItems),
                      languageCode,
                    ),
                    style: QType.num_(QType.caption).copyWith(color: q.ink2),
                  ),
                  if (milestone) ...[
                    const SizedBox(height: QSpace.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: QSpace.s2,
                        vertical: QSpace.s1,
                      ),
                      decoration: BoxDecoration(
                        color: q.accentSoft,
                        borderRadius: BorderRadius.circular(QRadius.full),
                      ),
                      child: Text(
                        LocaleDigits.localize(
                          l10n.streakMilestone(streak),
                          languageCode,
                        ),
                        style: QType.caption.copyWith(
                          color: q.onAccentSoft,
                          fontVariations: const [FontVariation('wght', 600)],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (streak > 0) ...[
              Icon(
                Icons.local_fire_department_outlined,
                size: 16,
                color: q.primary,
              ),
              const SizedBox(width: 2),
              Text(
                LocaleDigits.localize('$streak', languageCode),
                style: QType.num_(QType.titleSm).copyWith(color: q.ink),
              ),
              const SizedBox(width: QSpace.s2),
            ],
            Icon(Icons.chevron_right, size: 20, color: q.ink3),
          ],
        ),
      ),
    );
  }
}
