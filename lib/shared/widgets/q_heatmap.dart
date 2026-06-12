import 'package:flutter/widgets.dart';

import '../extensions/context_ext.dart';

/// GitHub-style heatmap cell: 13dp, radius 3.5, five intensity levels.
/// Level 0 reads "not yet" (surface-2) — NEVER a shame color.
final class QHeatmapCell extends StatelessWidget {
  const QHeatmapCell({required this.level, this.size = 13, super.key});

  /// 0..4; negative renders as an empty slot (out-of-range day).
  final int level;
  final double size;

  /// Level color: surface-2 → primary mixed at 25/50/75% → primary.
  static Color colorFor(BuildContext context, int level) {
    final q = context.q;
    return switch (level) {
      <= 0 => q.surface2,
      1 => Color.lerp(q.surface2, q.primary, 0.25)!,
      2 => Color.lerp(q.surface2, q.primary, 0.50)!,
      3 => Color.lerp(q.surface2, q.primary, 0.75)!,
      _ => q.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: level < 0
            ? const Color(0x00000000)
            : colorFor(context, level),
        borderRadius: BorderRadius.circular(3.5),
      ),
    );
  }
}

/// Column-per-week heatmap grid (dashboard). [weeks] is a list of columns,
/// each with 7 levels (-1 for out-of-range).
final class QHeatmap extends StatelessWidget {
  const QHeatmap({
    required this.weeks,
    this.cellSize = 13,
    this.gap = 3.5,
    super.key,
  });

  final List<List<int>> weeks;
  final double cellSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (w, week) in weeks.indexed) ...[
          if (w > 0) SizedBox(width: gap),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (d, level) in week.indexed) ...[
                if (d > 0) SizedBox(height: gap),
                QHeatmapCell(level: level, size: cellSize),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
