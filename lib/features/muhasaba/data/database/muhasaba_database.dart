import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'muhasaba_database.g.dart';

/// Tracker definitions; mirrors the domain `TrackerItem`.
@DataClassName('TrackerItemRow')
class TrackerItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Stored as `TrackerKind.code`.
  IntColumn get kind => integer()();
  IntColumn get dailyTarget => integer().nullable()();
  TextColumn get icon => text()();
  IntColumn get colorIndex => integer()();
  BoolColumn get isDefault => boolean()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();

  /// yyyymmdd of the first day the item counts toward daily completion
  /// (creation day, lowered if entries are back-filled earlier). Null =
  /// counts on every day.
  IntColumn get createdOn => integer().nullable()();

  /// yyyymmdd of the day it was archived (it stops counting from that day
  /// on); null while active.
  IntColumn get archivedOn => integer().nullable()();

  /// yyyymmdd of the real creation day — [createdOn] before any
  /// back-fill lowered it, so clearing those entries can raise it back.
  IntColumn get addedOn => integer().nullable()();

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

/// A finished archive span: the item didn't count on days
/// [startOn, endOn) (archived, then restored). The open span of an item
/// archived now is `TrackerItems.archivedOn`.
@DataClassName('ArchiveSpanRow')
class TrackerArchiveSpans extends Table {
  TextColumn get itemId => text().references(TrackerItems, #id)();

  /// yyyymmdd of the archive day (first day not counted).
  IntColumn get startOn => integer()();

  /// yyyymmdd of the restore day (counts again from this day).
  IntColumn get endOn => integer()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, startOn};
}

/// Drift/SQLite database backing the Muhasaba feature.
@DriftDatabase(tables: [TrackerItems, DailyEntries, TrackerArchiveSpans])
final class MuhasabaDatabase extends _$MuhasabaDatabase {
  /// Takes a [QueryExecutor] so tests can inject `NativeDatabase.memory()`.
  /// [clock] is the location wall clock (as the repository and store use);
  /// migrations take "today" from it.
  MuhasabaDatabase(super.executor, {DateTime Function() clock = DateTime.now})
    : _clock = clock;

  /// Opens the production on-device database file.
  static MuhasabaDatabase open({DateTime Function() clock = DateTime.now}) =>
      MuhasabaDatabase(driftDatabase(name: 'muhasaba'), clock: clock);

  final DateTime Function() _clock;

  /// Bump with every schema change, then export it and regenerate the
  /// migration-test helpers:
  /// `dart run drift_dev schema dump lib/features/muhasaba/data/database/muhasaba_database.dart drift_schemas/muhasaba/`
  /// `dart run drift_dev schema generate drift_schemas/muhasaba/ test/features/muhasaba/data/generated/`
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // One step per version, each with a case in
      // muhasaba_migration_test.dart.
      if (from < 2) {
        await m.addColumn(trackerItems, trackerItems.createdOn);
        await m.addColumn(trackerItems, trackerItems.archivedOn);
        // Conservative backfill (keeps past % as close to before as
        // possible): custom items start at their first entry, every
        // other item at the earliest entry overall (≈ install day).
        // Already-archived items never count (archived_on = created_on):
        // v1 left them out of every day, past ones included.
        final now = _clock();
        final today = now.year * 10000 + now.month * 100 + now.day;
        await customStatement(
          'UPDATE tracker_items SET created_on = COALESCE( '
          '(SELECT MIN(e.date) FROM daily_entries e '
          'WHERE e.item_id = tracker_items.id AND tracker_items.is_default = 0), '
          '(SELECT MIN(date) FROM daily_entries), ?)',
          [today],
        );
        await customStatement(
          'UPDATE tracker_items SET archived_on = created_on WHERE archived = 1',
        );
      }
      if (from < 3) {
        // Nothing to backfill: past restores weren't recorded, and an
        // item archived now keeps archived_on as its open span's start.
        await m.createTable(trackerArchiveSpans);
      }
      if (from < 4) {
        // Back-fills already applied can't be told apart: their lowered
        // created_on becomes the creation day.
        await m.addColumn(trackerItems, trackerItems.addedOn);
        await customStatement('UPDATE tracker_items SET added_on = created_on');
      }
    },
  );
}
