import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guide §2: the domain layer is pure Dart — no Flutter imports.
void main() {
  test('no domain file imports Flutter', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.path.contains('/domain/') &&
            f.readAsStringSync().contains("import 'package:flutter/"))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
