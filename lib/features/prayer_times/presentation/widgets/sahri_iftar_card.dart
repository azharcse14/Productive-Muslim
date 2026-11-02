import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';

/// Sahri end and iftar times side by side; just sahri when [iftar] is
/// null (after iftar, when the next sahri is tonight's). Strings arrive
/// formatted (digits included).
final class SahriIftarCard extends StatelessWidget {
  const SahriIftarCard({
    required this.sahriEnd,
    required this.iftar,
    this.sahriLabel,
    this.compact = false,
    super.key,
  });

  final String sahriEnd;
  final String? iftar;

  /// Defaults to "Sahri ends".
  final String? sahriLabel;

  /// One slim line per time (label beside time): the everyday form outside
  /// Ramadan / a fasted day.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? QSpace.s4 : QSpace.s5,
        vertical: compact ? QSpace.s3 : QSpace.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MealTime(
              label: sahriLabel ?? l10n.sahriEndsLabel,
              time: sahriEnd,
              icon: Icons.nightlight_outlined,
              compact: compact,
            ),
          ),
          if (iftar case final iftar?) ...[
            Container(
              width: 1,
              height: compact ? 20 : 36,
              color: context.q.line,
            ),
            const SizedBox(width: QSpace.s4),
            Expanded(
              child: _MealTime(
                label: l10n.iftarLabel,
                time: iftar,
                icon: Icons.wb_twilight_outlined,
                compact: compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _MealTime extends StatelessWidget {
  const _MealTime({
    required this.label,
    required this.time,
    required this.icon,
    required this.compact,
  });

  final String label;
  final String time;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    if (compact) {
      return Row(
        children: [
          Icon(icon, size: 16, color: q.ink3),
          const SizedBox(width: QSpace.s2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: QType.caption.copyWith(color: q.ink2),
            ),
          ),
          const SizedBox(width: QSpace.s2),
          Text(time, style: QType.num_(QType.label).copyWith(color: q.ink)),
        ],
      );
    }
    return Row(
      children: [
        Icon(icon, size: 19, color: q.ink2),
        const SizedBox(width: QSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: QType.caption.copyWith(color: q.ink2)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  time,
                  style: QType.num_(QType.titleSm).copyWith(color: q.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
