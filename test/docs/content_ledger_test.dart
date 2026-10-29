import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every bundled content file needs a source + license row in
/// docs/DEPENDENCIES.md, and a row may only say `OK` when it cites where the
/// license was read (a URL or an `owner/repo` path).
void main() {
  final ledger = File('docs/DEPENDENCIES.md').readAsStringSync();
  final section = ledger.substring(ledger.indexOf('## Fonts & Data Licenses'));
  final rows = [
    for (final line in section.split('\n'))
      if (line.startsWith('| ') && !line.startsWith('| Asset'))
        line.split('|').map((c) => c.trim()).toList(),
  ];

  test('every file in assets/data/ has a ledger row', () {
    final files = Directory('assets/data').listSync().whereType<File>().map(
      (f) => 'assets/data/${f.uri.pathSegments.last}',
    );
    final named = rows.map((r) => r[1]).join('\n');
    for (final file in files) {
      expect(named, contains(file), reason: '$file has no ledger row');
    }
  });

  test('no row is OK without a cited source', () {
    final cited = RegExp(r'https?://|\b[\w.-]+/[\w.-]+');
    expect(rows, isNotEmpty);
    for (final row in rows) {
      // | asset | source | license | status | checked |
      expect(row, hasLength(7), reason: row.join(' | '));
      if (row[4].startsWith('OK')) {
        expect(
          cited.hasMatch('${row[2]} ${row[3]}'),
          isTrue,
          reason: '${row[1]} is OK but cites no source',
        );
      }
    }
  });
}
