import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'muhasaba_database.g.dart';

/// Tracker definitions; mirrors the domain `TrackerItem`.
@DataClassName('TrackerItemRow')
class TrackerItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Stored as `TrackerKind.index`.
  IntColumn get kind => integer()();
  IntColumn get dailyTarget => integer().nullable()();
  TextColumn get icon => text()();
  IntColumn get colorIndex => integer()();
  BoolColumn get isDefault => boolean()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One logged value per tracker per civil day.
@DataClassName('DailyEntryRow')
class DailyEntries extends Table {
  TextColumn get itemId => text().references(TrackerItems, #id)();

  /// Civil day encoded as a yyyymmdd integer (e.g. 20260612). Integer
  /// encoding makes range queries (`BETWEEN`) and `GROUP BY` date cheap
  /// and avoids timezone ambiguity for date-only data.
  IntColumn get date => integer()();
  IntColumn get value => integer()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, date};
}

/// Drift/SQLite database backing the Muhasaba feature.
@DriftDatabase(tables: [TrackerItems, DailyEntries])
final class MuhasabaDatabase extends _$MuhasabaDatabase {
  /// Takes a [QueryExecutor] so tests can inject `NativeDatabase.memory()`.
  MuhasabaDatabase(super.executor);

  /// Opens the production on-device database file.
  static MuhasabaDatabase open() =>
      MuhasabaDatabase(driftDatabase(name: 'muhasaba'));

  /// Bump with every schema change, then export it and regenerate the
  /// migration-test helpers:
  /// `dart run drift_dev schema dump lib/features/muhasaba/data/database/muhasaba_database.dart drift_schemas/muhasaba/`
  /// `dart run drift_dev schema generate drift_schemas/muhasaba/ test/features/muhasaba/data/generated/`
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Add one step per version here (e.g. `if (from < 2) ...`) and a
          // case in muhasaba_migration_test.dart. Until then nothing to do —
          // fail loudly rather than open a mismatched schema.
          throw StateError('No muhasaba migration from v$from to v$to');
        },
      );
}
