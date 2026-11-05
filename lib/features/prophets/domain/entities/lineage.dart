import 'prophet.dart';

/// How a parent → child line is drawn.
enum LinkStyle {
  /// Direct parent → child.
  solid,

  /// Descent through many generations.
  dashed,
}

/// One row of the prophets timeline-tree. Lines run in columns: a line
/// reserved for a child runs down the child's column from the parent's row.
final class LineageRow {
  const LineageRow({
    required this.prophet,
    required this.column,
    this.incoming,
    this.through = const {},
    this.outgoing = const {},
  });

  final Prophet prophet;

  /// Indent column of this row's dot (0 = leftmost / start side).
  final int column;

  /// Line arriving from the parent above, in [column]; null for a root.
  final LinkStyle? incoming;

  /// Lines crossing this row top to bottom, by column (other rows' links).
  final Map<int, LinkStyle> through;

  /// Lines leaving this row's dot for its children, by the child's column.
  final Map<int, LinkStyle> outgoing;
}

/// Lays [prophets] out as timeline rows, sorted by `order`.
///
/// A prophet's first child (lowest order) continues in the parent's column;
/// later children branch into the lowest free column, so the tree stays as
/// narrow as the busiest row allows. Roots
/// (no parent, an unknown parent, or a parent that comes later) take the
/// lowest column no line is passing through, so dots never sit on another
/// prophet's line.
List<LineageRow> layoutLineage(Iterable<Prophet> prophets) {
  final sorted = [...prophets]..sort((a, b) => a.order.compareTo(b.order));
  final orderOf = {for (final p in sorted) p.id: p.order};
  LinkStyle? linkOf(Prophet p) => switch (orderOf[p.parent]) {
    final parentOrder? when parentOrder < p.order =>
      p.parentDistant ? LinkStyle.dashed : LinkStyle.solid,
    _ => null,
  };
  int free(Map<int, Object> taken, int from) {
    var column = from;
    while (taken.containsKey(column)) {
      column++;
    }
    return column;
  }

  // column → (child id, style) of a line waiting for that child.
  final reserved = <int, (String, LinkStyle)>{};
  return [
    for (final p in sorted)
      () {
        final column =
            reserved.entries
                .where((e) => e.value.$1 == p.id)
                .firstOrNull
                ?.key ??
            free(reserved, 0);
        final incoming = reserved[column]?.$1 == p.id
            ? reserved.remove(column)!.$2
            : null;
        final through = {for (final e in reserved.entries) e.key: e.value.$2};
        final outgoing = <int, LinkStyle>{};
        for (final child in sorted.where((c) => c.parent == p.id)) {
          if (linkOf(child) case final style?) {
            final at = outgoing.isEmpty ? column : free(reserved, 0);
            reserved[at] = (child.id, style);
            outgoing[at] = style;
          }
        }
        return LineageRow(
          prophet: p,
          column: column,
          incoming: incoming,
          through: through,
          outgoing: outgoing,
        );
      }(),
  ];
}
