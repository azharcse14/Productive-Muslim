import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A past find-and-replace rename split identifiers ("Productive MuslimColors")
/// and left the template app id behind. Keep docs and native comments clean.
void main() {
  final banned = RegExp(r'Productive Muslim[A-Z]|com\.productive_muslim\.');
  final files = [
    for (final dir in ['docs', 'android/app/src/main', 'ios'])
      ...Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => RegExp(r'\.(md|xml|kt|swift|plist)$').hasMatch(f.path)),
    File('README.md'),
  ];

  test('no split identifiers or stale app ids', () {
    final hits = [
      for (final f in files)
        for (final m in banned.allMatches(f.readAsStringSync()))
          '${f.path}: ${m[0]}',
    ];
    expect(hits, isEmpty);
  });
}
