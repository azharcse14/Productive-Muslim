import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('hadith_copy_'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// A tiny hadith.db at [HadithDatabase.bundledVersion]; [bengali] false is
  /// what tool/strip_bengali_hadith.dart leaves (same user_version).
  File db(String name, {required bool bengali}) {
    final f = File('${dir.path}/$name');
    final d = sqlite.sqlite3.open(f.path)
      ..execute('CREATE TABLE hadith_section(edition TEXT)')
      ..execute('PRAGMA user_version = ${HadithDatabase.bundledVersion}');
    if (bengali) {
      d.execute('CREATE TABLE hadith_bn_section(book_id TEXT)');
    }
    d.close();
    return f;
  }

  bool hasBengali(File f) {
    final d = sqlite.sqlite3.open(f.path);
    try {
      return d
          .select(
            "SELECT 1 FROM sqlite_master WHERE name = 'hadith_bn_section'",
          )
          .isNotEmpty;
    } finally {
      d.close();
    }
  }

  for (final bundled in [true, false]) {
    test('installed ${bundled ? 'stripped' : 'full'} copy is replaced by a '
        '${bundled ? 'full' : 'stripped'} asset at the same version', () async {
      final installed = db('installed.db', bengali: !bundled);
      final asset = db('asset.db', bengali: bundled);
      await HadithDatabase.ensureCopied(
        installed,
        () async => ByteData.sublistView(asset.readAsBytesSync()),
        bengali: bundled,
      );
      expect(hasBengali(installed), bundled);
    });

    test('an asset mismatching the build (bengali: ${!bundled}) is copied '
        'once, not on every launch', () async {
      final installed = File('${dir.path}/installed.db');
      final asset = db('asset.db', bengali: bundled);
      var loads = 0;
      for (var launch = 0; launch < 3; launch++) {
        await HadithDatabase.ensureCopied(installed, () async {
          loads++;
          return ByteData.sublistView(asset.readAsBytesSync());
        }, bengali: !bundled);
      }
      expect(loads, 1);
      expect(hasBengali(installed), bundled);
    });

    test(
      'a ${bundled ? 'full' : 'stripped'} copy matching the build is kept',
      () async {
        final installed = db('installed.db', bengali: bundled);
        await HadithDatabase.ensureCopied(
          installed,
          () => fail('must not re-read the asset'),
          bengali: bundled,
        );
      },
    );
  }
}
