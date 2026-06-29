import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/achievements.dart';
import '../state/achievement_store.dart';
import '../widgets/achievement_card.dart';

/// Achievements / badges — a no-shame milestone wall driven entirely by the
/// user's existing activity. Locked badges show how close the next tier is;
/// nothing is ever framed as failure.
final class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

final class _AchievementsScreenState extends State<AchievementsScreen> {
  // App-scoped store — never disposed here.
  late final AchievementStore _store = locator<AchievementStore>();

  @override
  void initState() {
    super.initState();
    // Refresh totals on entry, then mark everything seen.
    unawaited(_store.refresh().then((_) => _store.markAllSeen()));
  }

  static const _order = <AchievementCategory>[
    AchievementCategory.streaks,
    AchievementCategory.salah,
    AchievementCategory.dhikr,
    AchievementCategory.quran,
    AchievementCategory.fasting,
  ];

  String _categoryName(AppLocalizations l10n, AchievementCategory c) =>
      l10n.achievementCategory(c.name);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final byCategory =
                <AchievementCategory, List<AchievementProgress>>{};
            for (final p in _store.progress.value) {
              byCategory.putIfAbsent(p.achievement.category, () => []).add(p);
            }
            return ListView(
              padding: const EdgeInsets.all(QSpace.s5),
              children: [
                _summary(context),
                const SizedBox(height: QSpace.s4),
                for (final category in _order)
                  if (byCategory[category] case final items?
                      when items.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: QSpace.s1,
                        bottom: QSpace.s3,
                      ),
                      child: Text(
                        _categoryName(l10n, category).toUpperCase(),
                        style: context.text.labelSmall,
                      ),
                    ),
                    QCard(child: _grid(items)),
                    const SizedBox(height: QSpace.s4),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _grid(List<AchievementProgress> items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: QSpace.s4,
          crossAxisSpacing: QSpace.s3,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => AchievementCard(progress: items[i]),
      );

  Widget _summary(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final locale = Localizations.localeOf(context).languageCode;
    final unlocked = _store.unlockedCount.value;
    final total = _store.totalCount.value;
    return QCard(
      tone: q.primarySoft,
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 34,
            color: q.onPrimarySoft,
          ),
          const SizedBox(width: QSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleDigits.localize('$unlocked / $total', locale),
                  style:
                      QType.num_(QType.title).copyWith(color: q.onPrimarySoft),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.achievementsSubtitle,
                  style: QType.caption.copyWith(color: q.onPrimarySoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
