import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/muhasaba/data/database/muhasaba_database.dart';

import 'generated/schema.dart';

/// Pins the live schema to the exported dumps in drift_schemas/muhasaba/.
/// Changing a table without bumping schemaVersion (and re-exporting) fails
/// here; each future version adds a `migrateAndValidate` case.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a fresh database matches the exported v2 schema', () async {
    final schema = await verifier.schemaAt(2);
    final db = MuhasabaDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test(
    'v1 -> v2 adds created/archived days with a conservative backfill',
    () async {
      final schema = await verifier.schemaAt(1);
      final raw = schema.rawDatabase;
      raw.execute(
        "INSERT INTO tracker_items (id, name, kind, icon, color_index, "
        "is_default, archived, sort_order) VALUES "
        "('salah_fajr', 'f', 0, 'm', 0, 1, 0, 0), "
        "('custom_1', 'c', 0, 'm', 0, 0, 1, 1)",
      );
      raw.execute(
        "INSERT INTO daily_entries (item_id, date, value) VALUES "
        "('salah_fajr', 20260301, 1), ('custom_1', 20260505, 1)",
      );
      final db = MuhasabaDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
      final rows = {
        for (final r in await db.select(db.trackerItems).get()) r.id: r,
      };
      // Default -> earliest entry overall; custom -> its own first entry.
      expect(rows['salah_fajr']!.createdOn, 20260301);
      expect(rows['salah_fajr']!.archivedOn, isNull);
      expect(rows['custom_1']!.createdOn, 20260505);
      expect(rows['custom_1']!.archivedOn, isNotNull);
      await db.close();
    },
  );
}
