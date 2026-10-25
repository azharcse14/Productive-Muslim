import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';

/// Today's sahri end and iftar times side by side. Strings arrive
/// formatted (digits included).
final class SahriIftarCard extends StatelessWidget {
  const SahriIftarCard({
    required this.sahriEnd,
    required this.iftar,
    super.key,
  });

  final String sahriEnd;
  final String iftar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s5,
        vertical: QSpace.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MealTime(
              label: l10n.sahriEndsLabel,
              time: sahriEnd,
              icon: Icons.nightlight_outlined,
            ),
          ),
          Container(width: 1, height: 36, color: context.q.line),
          const SizedBox(width: QSpace.s4),
          Expanded(
            child: _MealTime(
              label: l10n.iftarLabel,
              time: iftar,
              icon: Icons.wb_twilight_outlined,
            ),
          ),
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
  });

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Row(
      children: [
        Icon(icon, size: 19, color: q.ink2),
        const SizedBox(width: QSpace.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: QType.caption.copyWith(color: q.ink2)),
            Text(time, style: QType.num_(QType.titleSm).copyWith(color: q.ink)),
          ],
        ),
      ],
    );
  }
}
