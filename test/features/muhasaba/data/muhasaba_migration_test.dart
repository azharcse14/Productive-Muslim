import 'package:drift/drift.dart';
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

  test('a fresh v1 database matches the exported v1 schema', () async {
    final schema = await verifier.schemaAt(1);
    final db = MuhasabaDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

}
