import '../../../../core/utils/result.dart';
import '../entities/daily_entry.dart';
import '../entities/period_stats.dart';
import '../entities/tracker_item.dart';

/// Muhasaba persistence (drift/SQLite in the data layer). Aggregations
/// run as SQL queries, not in-memory loops over full history (guide §5).
abstract interface class MuhasabaRepository {
  /// Inserts any [DefaultTrackers.items] not yet stored (archived on an
  /// existing install); never touches existing rows.
  Future<Result<void>> seedDefaults();

  Future<Result<List<TrackerItem>>> items({bool includeArchived = false});

  /// Insert or update (by id). Custom item creation and edits.
  Future<Result<void>> upsertItem(TrackerItem item);

  /// Persists the checklist order: [ids][i] gets sortOrder i.
  Future<Result<void>> reorder(List<String> ids);

  /// Archive (or restore) — never deletes; history stays intact.
  Future<Result<void>> setArchived(String id, {required bool archived});

  Future<Result<List<DailyEntry>>> entriesOn(DateTime date);

  /// Upsert by (itemId, date); value 0 removes the row. Any write for an
  /// archived tracker is refused with [ArchivedTrackerFailure]: it takes
  /// no new entries (or it would keep streaks and badges alive) and its
  /// history stays as it was.
  Future<Result<void>> setEntry(DailyEntry entry);

  /// Aggregates for [start]..[end] inclusive (date-only), with streaks
  /// anchored at [today] and the equal-length previous window's
  /// completion for the trend comparison.
  Future<Result<PeriodStats>> periodStats({
    required DateTime start,
    required DateTime end,
    required DateTime today,
  });

  /// All-time distinct dates on which any of [itemIds] was completed,
  /// archived items included (achievements count every logged day).
  Future<Result<Set<DateTime>>> doneDates(Set<String> itemIds);

  /// How many [doneDates] there are, counted in SQL.
  Future<Result<int>> doneDayCount(Set<String> itemIds);

  /// All-time current and best run of consecutive days with any item
  /// done, archived items included — the same streaks [periodStats]
  /// reports. The current run may end yesterday: today still counts
  /// until it passes empty.
  Future<Result<({int current, int best})>> streaks(DateTime today);
}

/// [MuhasabaRepository.setEntry] refused a value for an archived tracker.
/// Expected, not an error: callers drop the write without telling the user.
final class ArchivedTrackerFailure extends Failure {
  const ArchivedTrackerFailure() : super('Tracker is archived');
}
