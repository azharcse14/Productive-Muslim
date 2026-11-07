import 'dart:math' as math;

import 'package:flutter/material.dart';

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
        color: level < 0 ? Colors.transparent : colorFor(context, level),
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
    this.maxCellSize,
    this.reverse = false,
    super.key,
  });

  final List<List<int>> weeks;
  final double cellSize;
  final double gap;

  /// Fit to the available width: cells grow from [cellSize] up to this so
  /// short ranges fill the card, and the grid is centered. Grids wider than
  /// the space keep [cellSize] and scroll horizontally. Null = fixed
  /// [cellSize], no scrolling (the caller lays it out). Needs bounded width.
  final double? maxCellSize;

  /// With [maxCellSize]: scroll from the end so the newest week shows first.
  final bool reverse;

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
    final max = maxCellSize;
    if (max == null) {
      return _grid(context, cellSize);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = weeks.length;
        final fit = n == 0
            ? cellSize
            : (constraints.maxWidth - gap * (n - 1)) / n;
        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: reverse,
            child: _grid(context, fit.clamp(cellSize, math.max(cellSize, max))),
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context, double size) {
    Widget cell(int w, int d, int level) {
      final box = QHeatmapCell(
        level: level,
        size: size,
        outlined: highlight == (w, d),
      );
      final tap = onTap;
      if (tap == null || level < 0) {
        return box;
      }
      // Screen readers act per cell; touch goes through the grid-wide
      // detector below so the gaps count too.
      return Semantics(
        button: true,
        label: cellLabel?.call(w, d),
        excludeSemantics: true,
        onTap: () => tap(w, d),
        child: box,
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
    Widget grid = cellLabel != null && onTap != null
        ? rows
        : ExcludeSemantics(child: rows);
    final tap = onTap;
    if (tap != null) {
      // One detector over the whole grid: a 13dp cell is far below the 48dp
      // touch minimum, so a tap anywhere (gaps included) picks the nearest.
      final rtl = Directionality.of(context) == TextDirection.rtl;
      grid = GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapUp: (details) {
          if (weeks.isEmpty) {
            return;
          }
          final pitch = size + gap;
          final width = weeks.length * pitch - gap;
          final x = rtl
              ? width - details.localPosition.dx
              : details.localPosition.dx;
          final w = ((x + gap / 2) / pitch).floor().clamp(0, weeks.length - 1);
          final week = weeks[w];
          if (week.isEmpty) {
            return;
          }
          final d = ((details.localPosition.dy + gap / 2) / pitch)
              .floor()
              .clamp(0, week.length - 1);
          if (week[d] >= 0) {
            tap(w, d);
          }
        },
        child: grid,
      );
    }
    if (semanticLabel == null) {
      return grid;
    }
    return Semantics(label: semanticLabel, child: grid);
  }
}
