import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';
import 'q_card.dart';

/// Grid tile for a content category: tonal icon, name and a count line.
/// Announced as one button ("name, count").
final class QCategoryTile extends StatelessWidget {
  const QCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: QCard(
        onTap: onTap,
        padding: const EdgeInsets.all(QSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: q.primarySoft,
                borderRadius: BorderRadius.circular(QRadius.sm),
              ),
              child: Icon(icon, size: 19, color: q.onPrimarySoft),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: QType.titleSm.copyWith(color: q.ink),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: QType.caption.copyWith(color: q.ink2)),
          ],
        ),
      ),
    );
  }
}
