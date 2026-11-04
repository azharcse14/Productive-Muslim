import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/muhasaba/data/database/muhasaba_database.dart';
import 'package:productive_muslim/features/muhasaba/data/repositories/muhasaba_repository_impl.dart';

import 'generated/schema.dart';

/// Pins the live schema to the exported dumps in drift_schemas/muhasaba/.
/// Changing a table without bumping schemaVersion (and re-exporting) fails
/// here; each future version adds a `migrateAndValidate` case.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a fresh database matches the exported v5 schema', () async {
    final schema = await verifier.schemaAt(5);
    final db = MuhasabaDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    await db.close();
  });

  test('v4 -> v5 adds empty expense tables; trackers untouched', () async {
    final schema = await verifier.schemaAt(4);
    schema.rawDatabase.execute(
      "INSERT INTO tracker_items (id, name, kind, icon, color_index, "
      "is_default, archived, sort_order, created_on, archived_on, added_on) "
      "VALUES ('quran', 'q', 0, 'm', 0, 1, 0, 0, 20250801, NULL, 20250801)",
    );
    final db = MuhasabaDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    expect(await db.select(db.expenses).get(), isEmpty);
    expect(await db.select(db.expenseBudgets).get(), isEmpty);
    expect((await db.select(db.trackerItems).getSingle()).addedOn, 20250801);
    await db.close();
  });

  test('v3 -> v5 copies created_on into added_on', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute(
      "INSERT INTO tracker_items (id, name, kind, icon, color_index, "
      "is_default, archived, sort_order, created_on, archived_on) VALUES "
      "('quran', 'q', 0, 'm', 0, 1, 0, 0, 20250801, NULL), "
      "('old', 'o', 0, 'm', 0, 1, 0, 1, NULL, NULL)",
    );
    final db = MuhasabaDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    final rows = {
      for (final r in await db.select(db.trackerItems).get()) r.id: r,
    };
    expect(rows['quran']!.addedOn, 20250801);
    expect(rows['old']!.addedOn, isNull);
    await db.close();
  });

  test('v2 -> v5 adds archive spans; an archived item stays open', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute(
      "INSERT INTO tracker_items (id, name, kind, icon, color_index, "
      "is_default, archived, sort_order, created_on, archived_on) VALUES "
      "('quran', 'q', 0, 'm', 0, 1, 1, 0, 20250801, 20260610), "
      "('dhikr', 'd', 0, 'm', 0, 1, 0, 1, 20250801, NULL)",
    );
    final db = MuhasabaDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    expect(await db.select(db.trackerArchiveSpans).get(), isEmpty);
    final quran = await (db.select(
      db.trackerItems,
    )..where((t) => t.id.equals('quran'))).getSingle();
    expect(quran.archivedOn, 20260610);
    expect(quran.createdOn, 20250801);
    await db.close();
  });

  test(
    'v1 -> v5 directly: conservative backfill, past completion unchanged',
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
        "('salah_fajr', 20260301, 1), ('custom_1', 20260505, 1), "
        "('salah_fajr', 20260601, 1)",
      );
      final db = MuhasabaDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 5);
      final rows = {
        for (final r in await db.select(db.trackerItems).get()) r.id: r,
      };
      // Default -> earliest entry overall; custom -> its own first entry.
      expect(rows['salah_fajr']!.createdOn, 20260301);
      expect(rows['salah_fajr']!.archivedOn, isNull);
      expect(rows['custom_1']!.createdOn, 20260505);
      // Archived in v1 -> never counted (as v1 left it out of every day).
      expect(rows['custom_1']!.archivedOn, 20260505);
      expect(rows['custom_1']!.addedOn, 20260505);

      // v1 completion: archived custom_1 left out of both sides.
      final stats = await MuhasabaRepositoryImpl(db).periodStats(
        start: DateTime(2026, 5, 5),
        end: DateTime(2026, 6),
        today: DateTime(2026, 6),
      );
      final days = stats.valueOrNull!.days;
      expect(days.first.completion, 0, reason: 'May 5: fajr not done');
      expect(days.last.completion, 1, reason: 'Jun 1: fajr done = 100%');
      await db.close();
    },
  );

  test(
    'v1 with no entries backfills created_on from the injected clock',
    () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute(
        "INSERT INTO tracker_items (id, name, kind, icon, color_index, "
        "is_default, archived, sort_order) VALUES "
        "('salah_fajr', 'f', 0, 'm', 0, 1, 0, 0)",
      );
      // The location's wall clock, not the device's.
      final db = MuhasabaDatabase(
        schema.newConnection(),
        clock: () => DateTime(2031, 1, 2, 23, 30),
      );
      await verifier.migrateAndValidate(db, 5);
      final row = await db.select(db.trackerItems).getSingle();
      expect(row.createdOn, 20310102);
      expect(row.addedOn, 20310102);
      await db.close();
    },
  );
}
