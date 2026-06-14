import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../state/achievement_store.dart';

/// Compact achievements teaser for the muhasaba dashboard. Tapping opens the
/// full badge wall.
final class AchievementsSummaryCard extends StatelessWidget {
  const AchievementsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = locator<AchievementStore>();
    final q = context.q;
    final l10n = context.l10n;
    return SignalBuilder(
      builder: (context) {
        final unlocked = store.unlockedCount.value;
        final total = store.totalCount.value;
        return InkWell(
          borderRadius: BorderRadius.circular(QRadius.lg),
          onTap: () => context.pushNamed(Routes.achievements.name),
          child: QCard(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: q.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    size: 20,
                    color: q.onAccentSoft,
                  ),
                ),
                const SizedBox(width: QSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.achievementsTitle,
                        style: QType.titleSm.copyWith(color: q.ink),
                      ),
                      Text(
                        l10n.achievementsCount(unlocked, total),
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: q.ink3),
              ],
            ),
          ),
        );
      },
    );
  }
}
