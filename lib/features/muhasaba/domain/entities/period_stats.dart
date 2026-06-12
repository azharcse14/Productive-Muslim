/// One day's overall completion (0..1 across non-archived items active
/// that day). Drives the heatmap and trend line.
final class DayCompletion {
  const DayCompletion(this.date, this.completion);

  final DateTime date;
  final double completion;

  @override
  bool operator ==(Object other) =>
      other is DayCompletion &&
      other.date == date &&
      other.completion == completion;

  @override
  int get hashCode => Object.hash(date, completion);
}

/// Per-item aggregate over a period (dashboard bars).
final class ItemPeriodStats {
  const ItemPeriodStats({
    required this.itemId,
    required this.daysDone,
    required this.periodDays,
    required this.totalValue,
  });

  final String itemId;

  /// Days the item was completed within the period.
  final int daysDone;

  /// Days in the period (denominator for the bar).
  final int periodDays;

  /// Sum of values (counts/minutes; yesNo = done-day count).
  final int totalValue;

  double get completion =>
      periodDays == 0 ? 0 : (daysDone / periodDays).clamp(0, 1).toDouble();

  @override
  bool operator ==(Object other) =>
      other is ItemPeriodStats &&
      other.itemId == itemId &&
      other.daysDone == daysDone &&
      other.periodDays == periodDays &&
      other.totalValue == totalValue;

  @override
  int get hashCode =>
      Object.hash(itemId, daysDone, periodDays, totalValue);
}

/// Dashboard aggregate for a date range (design §4.7). All framed
/// positively — never "failed" semantics.
final class PeriodStats {
  const PeriodStats({
    required this.completion,
    required this.days,
    required this.items,
    required this.currentStreak,
    required this.bestStreak,
    this.previousCompletion,
  });

  /// Mean of day completions over the period, 0..1.
  final double completion;

  /// One entry per day in the range (inclusive), chronological.
  final List<DayCompletion> days;
  final List<ItemPeriodStats> items;

  /// Streak = consecutive days (ending today/yesterday) with at least
  /// one completed item. Positive framing: any progress keeps it alive.
  final int currentStreak;
  final int bestStreak;

  /// Completion of the equal-length window immediately before the range
  /// (null when no prior data) — "vs previous period" trend.
  final double? previousCompletion;
}
