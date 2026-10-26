import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_progress_ring.dart';

/// Compact inline tasbih (dhikr) counter card for the home screen.
/// Purely presentational: count/target come in via params, taps are reported
/// via callbacks — no store/locator/SignalBuilder inside.
final class TasbihQuickCard extends StatelessWidget {
  const TasbihQuickCard({
    required this.count,
    required this.target,
    required this.onTap,
    this.onReset,
    this.onOpen,
    super.key,
  });

  final int count;
  final int target;

  /// Increment tap (the big counter ring).
  final VoidCallback onTap;

  /// Reset the counter (optional refresh icon).
  final VoidCallback? onReset;

  /// Open the full tasbih screen (optional chevron).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final progress = target == 0 ? 0.0 : (count / target).clamp(0.0, 1.0);

    return QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s5,
        vertical: QSpace.s4,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.tasbihQuickHint,
            value: LocaleDigits.localize('$count / $target', lang),
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: QProgressRing(
                progress: progress,
                size: 56,
                strokeWidth: 6,
                child: Text(
                  LocaleDigits.localize('$count', lang),
                  style: QType.num_(QType.titleSm).copyWith(color: q.ink),
                ),
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
                  l10n.tasbihQuickTitle,
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.tasbihQuickHint,
                  style: QType.caption.copyWith(color: q.ink2),
                ),
                Text(
                  LocaleDigits.localize('$count / $target', lang),
                  style: QType.num_(QType.caption).copyWith(color: q.ink3),
                ),
              ],
            ),
          ),
          if (onReset != null)
            IconButton(
              tooltip: l10n.tasbihReset,
              onPressed: onReset,
              icon: Icon(Icons.refresh, color: q.ink3),
            ),
          if (onOpen != null)
            IconButton(
              tooltip: l10n.tasbihTitle,
              onPressed: onOpen,
              icon: Icon(Icons.chevron_right, color: q.ink3),
            ),
        ],
      ),
    );
  }
}
