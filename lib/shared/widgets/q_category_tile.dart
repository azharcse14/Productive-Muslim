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

  static const double _iconSize = 38;

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
        // Grids size tiles from a fixed aspect ratio, which can leave too
        // little height for two title lines (narrow phones, 1.0× text);
        // then the title drops to one ellipsized line instead of overflowing.
        child: LayoutBuilder(
          builder: (context, box) {
            final scaler = MediaQuery.textScalerOf(context);
            double lineOf(TextStyle s) => scaler.scale(s.fontSize!) * s.height!;
            final titleLines =
                box.maxHeight - _iconSize - 2 - lineOf(QType.caption) >=
                    2 * lineOf(QType.titleSm)
                ? 2
                : 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: q.primarySoft,
                    borderRadius: BorderRadius.circular(QRadius.sm),
                  ),
                  child: Icon(icon, size: 19, color: q.onPrimarySoft),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: titleLines,
                  overflow: TextOverflow.ellipsis,
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QType.caption.copyWith(color: q.ink2),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
