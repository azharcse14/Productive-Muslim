import 'package:flutter/widgets.dart';

import '../extensions/context_ext.dart';

/// GitHub-style heatmap cell: 13dp, radius 3.5, five intensity levels.
/// Level 0 reads "not yet" (surface-2) — NEVER a shame color.
final class QHeatmapCell extends StatelessWidget {
  const QHeatmapCell({
    required this.level,
    this.size = 13,
    this.outlined = false,
    super.key,
  });

  /// 0..4; negative renders as an empty slot (out-of-range day).
  final int level;
  final double size;

  /// Ink ring marking a special cell (today).
  final bool outlined;

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
        color: level < 0 ? const Color(0x00000000) : colorFor(context, level),
        borderRadius: BorderRadius.circular(3.5),
        border: outlined ? Border.all(color: context.q.ink, width: 1.5) : null,
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
    this.semanticLabel,
    this.highlight,
    this.onTap,
    this.cellLabel,
    super.key,
  });

  final List<List<int>> weeks;
  final double cellSize;
  final double gap;

  /// (week, day) of the cell to outline (e.g. today).
  final (int, int)? highlight;

  /// Tap on an in-range cell (week, day). Null = static grid.
  final void Function(int week, int day)? onTap;

  /// Spoken name of a tappable cell; with [onTap], cells become buttons.
  final String Function(int week, int day)? cellLabel;

  /// Optional spoken summary of the grid (e.g. "12 of 30 days completed").
  /// Unless [cellLabel] is given, cells are excluded from the a11y tree and
  /// this label stands in for the whole map.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget cell(int w, int d, int level) {
      final box = QHeatmapCell(
        level: level,
        size: cellSize,
        outlined: highlight == (w, d),
      );
      final tap = onTap;
      if (tap == null || level < 0) {
        return box;
      }
      return Semantics(
        button: true,
        label: cellLabel?.call(w, d),
        excludeSemantics: true,
        onTap: () => tap(w, d),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => tap(w, d),
          child: box,
        ),
      );
    }

    final rows = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (w, week) in weeks.indexed) ...[
          if (w > 0) SizedBox(width: gap),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (d, level) in week.indexed) ...[
                if (d > 0) SizedBox(height: gap),
                cell(w, d, level),
              ],
            ],
          ),
        ],
      ],
    );
    // Static cells carry no per-day meaning; tappable ones label themselves.
    final grid = cellLabel != null && onTap != null
        ? rows
        : ExcludeSemantics(child: rows);
    if (semanticLabel == null) {
      return grid;
    }
    return Semantics(label: semanticLabel, child: grid);
  }
}
