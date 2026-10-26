import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../../domain/achievements.dart';
import 'achievement_visuals.dart';

/// One badge tile. Unlocked = colored icon on a soft tonal disc; locked =
/// greyed icon inside a progress ring showing how close the next tier is.
final class AchievementCard extends StatelessWidget {
  const AchievementCard({required this.progress, super.key});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final a = progress.achievement;
    final unlocked = progress.unlocked;
    final tint = AchievementIcons.tierColor(q, a.tier);
    final icon = AchievementIcons.of(a.iconKey);
    final locale = Localizations.localeOf(context).languageCode;

    final disc = SizedBox.square(
      dimension: 64,
      child: unlocked
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AchievementIcons.tierSoft(q, a.tier),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 28, color: tint)),
            )
          : QProgressRing(
              progress: progress.fraction,
              size: 64,
              strokeWidth: 5,
              color: q.ink3,
              child: Icon(icon, size: 26, color: q.ink3),
            ),
    );

    return Semantics(
      button: true,
      label: l10n.achievementName(a.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(QRadius.md),
        onTap: () => _showHow(context),
        child: Opacity(
          opacity: unlocked ? 1 : 0.85,
          child: Column(
            children: [
              disc,
              const SizedBox(height: QSpace.s2),
              Text(
                l10n.achievementName(a.id),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: QType.caption.copyWith(
                  color: unlocked ? q.ink : q.ink2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unlocked
                    ? l10n.achievementUnlocked
                    : LocaleDigits.localize(
                        '${progress.current} / ${a.threshold}',
                        locale,
                      ),
                textAlign: TextAlign.center,
                style: QType.num_(
                  QType.caption,
                ).copyWith(color: unlocked ? q.ok : q.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Locked badges otherwise only say "3 / 7" — explain what earns them.
  void _showHow(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final a = progress.achievement;
    final kind = switch (a.id) {
      'quran_start' => 'quranStart',
      'quran_bookmark_5' => 'bookmark',
      final id => id.split('_').first,
    };
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              QSpace.s5,
              0,
              QSpace.s5,
              QSpace.s6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.achievementName(a.id),
                  style: QType.title.copyWith(color: q.ink),
                ),
                const SizedBox(height: QSpace.s2),
                Text(
                  l10n.achievementHow(kind, context.digits('${a.threshold}')),
                  style: QType.body.copyWith(color: q.ink2),
                ),
                const SizedBox(height: QSpace.s3),
                Text(
                  progress.unlocked
                      ? l10n.achievementUnlocked
                      : context.digits('${progress.current} / ${a.threshold}'),
                  style: QType.num_(
                    QType.label,
                  ).copyWith(color: progress.unlocked ? q.ok : q.ink2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
