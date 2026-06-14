/// Pure, date-seeded "content of the day" selection (no Random, no
/// DateTime.now). Same calendar day → same pick; varies day to day.
///
/// Callers pass the pool sizes; this maps the date to a deterministic index
/// into each pool. Keeping it pure makes determinism + boundaries
/// unit-testable.
library;

/// Which content type the daily reminder surfaces.
enum DailyContentKind { ayah, hadith, dua }

/// Deterministic indices into the ayah / hadith / dua pools for a given day.
/// An index is null when its pool is empty (size <= 0).
final class DailyContentSelection {
  const DailyContentSelection({
    required this.ayahIndex,
    required this.hadithIndex,
    required this.duaIndex,
  });

  final int? ayahIndex;
  final int? hadithIndex;
  final int? duaIndex;

  int? indexFor(DailyContentKind kind) => switch (kind) {
        DailyContentKind.ayah => ayahIndex,
        DailyContentKind.hadith => hadithIndex,
        DailyContentKind.dua => duaIndex,
      };

  @override
  bool operator ==(Object other) =>
      other is DailyContentSelection &&
      other.ayahIndex == ayahIndex &&
      other.hadithIndex == hadithIndex &&
      other.duaIndex == duaIndex;

  @override
  int get hashCode => Object.hash(ayahIndex, hadithIndex, duaIndex);
}

/// Days since the local epoch — a monotonic, calendar-day-stable seed that
/// (unlike day-of-year) never repeats across a year boundary, so the rotation
/// doesn't "reset" every January 1st. Uses only the date's y/m/d.
int dailySeed(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  return utc.difference(DateTime.utc(1970)).inDays;
}

/// Maps [date] to one deterministic index per pool. Each pool is offset by a
/// fixed prime so the three picks don't move in lockstep day to day.
DailyContentSelection pickDailyContent({
  required DateTime date,
  required int ayahPoolSize,
  required int hadithPoolSize,
  required int duaPoolSize,
}) {
  final seed = dailySeed(date);
  int? index(int poolSize, int offset) =>
      poolSize <= 0 ? null : (seed + offset) % poolSize;
  return DailyContentSelection(
    ayahIndex: index(ayahPoolSize, 0),
    hadithIndex: index(hadithPoolSize, 3),
    duaIndex: index(duaPoolSize, 7),
  );
}
