import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/prophets/domain/entities/lineage.dart';
import 'package:productive_muslim/features/prophets/domain/entities/prophet.dart';

Prophet _p(String id, int order, {String? parent, bool distant = false}) =>
    Prophet(
      id: id,
      order: order,
      nameAr: id,
      nameEn: id,
      nameBn: id,
      parent: parent,
      parentDistant: distant,
    );

Map<String, LineageRow> _byId(List<LineageRow> rows) => {
  for (final r in rows) r.prophet.id: r,
};

void main() {
  group('layoutLineage', () {
    test('Ibrahim branches to Ismail and Ishaq; Ishaq → Yaqub → Yusuf '
        'continues one column', () {
      final rows = layoutLineage([
        // Shuffled on purpose: the layout sorts by order.
        _p('yusuf', 5, parent: 'yaqub'),
        _p('ibrahim', 1),
        _p('ishaq', 3, parent: 'ibrahim'),
        _p('ismail', 2, parent: 'ibrahim'),
        _p('yaqub', 4, parent: 'ishaq'),
      ]);
      expect(rows.map((r) => r.prophet.id), [
        'ibrahim',
        'ismail',
        'ishaq',
        'yaqub',
        'yusuf',
      ]);
      final r = _byId(rows);
      expect(r['ibrahim']!.column, 0);
      expect(r['ibrahim']!.incoming, isNull);
      expect(r['ibrahim']!.outgoing, {0: LinkStyle.solid, 1: LinkStyle.solid});
      // First child continues the parent's column; Ishaq's line passes it.
      expect(r['ismail']!.column, 0);
      expect(r['ismail']!.incoming, LinkStyle.solid);
      expect(r['ismail']!.through, {1: LinkStyle.solid});
      expect(r['ismail']!.outgoing, isEmpty);
      for (final id in ['ishaq', 'yaqub', 'yusuf']) {
        expect(r[id]!.column, 1, reason: id);
        expect(r[id]!.incoming, LinkStyle.solid, reason: id);
        expect(r[id]!.through, isEmpty, reason: id);
      }
      expect(r['ishaq']!.outgoing, {1: LinkStyle.solid});
      expect(r['yusuf']!.outgoing, isEmpty);
    });

    test('null, unknown and later parents make a root with no line', () {
      final rows = layoutLineage([
        _p('none', 1),
        _p('unknown', 2, parent: 'nobody'),
        _p('early', 3, parent: 'late'),
        _p('late', 4),
      ]);
      for (final row in rows) {
        expect(row.column, 0, reason: row.prophet.id);
        expect(row.incoming, isNull, reason: row.prophet.id);
        expect(row.through, isEmpty, reason: row.prophet.id);
        expect(row.outgoing, isEmpty, reason: row.prophet.id);
      }
    });

    test('a distant descent is dashed all the way down', () {
      final r = _byId(
        layoutLineage([
          _p('ismail', 1),
          _p('between', 2),
          _p('muhammad', 3, parent: 'ismail', distant: true),
        ]),
      );
      expect(r['ismail']!.outgoing, {0: LinkStyle.dashed});
      // The root in between steps aside from the passing dashed line.
      expect(r['between']!.column, 1);
      expect(r['between']!.through, {0: LinkStyle.dashed});
      expect(r['muhammad']!.column, 0);
      expect(r['muhammad']!.incoming, LinkStyle.dashed);
    });

    test('a later child reuses a freed column on the start side', () {
      final r = _byId(
        layoutLineage([
          _p('a', 1),
          _p('b', 2, parent: 'a'),
          _p('c', 3, parent: 'a'),
          _p('d', 4, parent: 'c'),
          _p('e', 5, parent: 'c'),
        ]),
      );
      // b ends column 0; c sits in column 1 and branches e back into 0.
      expect(r['c']!.column, 1);
      expect(r['c']!.outgoing, {1: LinkStyle.solid, 0: LinkStyle.solid});
      expect(r['e']!.column, 0);
    });

    test('a root never lands on a passing line', () {
      final r = _byId(
        layoutLineage([
          _p('a', 1),
          _p('b', 2, parent: 'a'),
          _p('c', 3, parent: 'a'),
          _p('root', 4),
          _p('d', 5, parent: 'c'),
        ]),
      );
      // After b, c's line holds column 1 and d's line will take it next.
      expect(r['c']!.column, 1);
      expect(r['root']!.through, {1: LinkStyle.solid});
      expect(r['root']!.column, 0);
      expect(r['d']!.column, 1);
    });
  });
}
