/// Immutable snapshot of the user's real activity, assembled from the
/// existing muhasaba / tasbih / quran stores. The pure achievement layer
/// reads ONLY these fields — never DateTime.now, Random, or Flutter — so
/// every threshold is unit-testable by passing values in.
final class AchievementStats {
  const AchievementStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.salahDaysDone = 0,
    this.quranDaysDone = 0,
    this.fastingDaysDone = 0,
    this.tahajjudDaysDone = 0,
    this.sadaqahDaysDone = 0,
    this.totalDhikr = 0,
    this.tasbihSessions = 0,
    this.quranBookmarks = 0,
    this.hasStartedReading = false,
  });

  /// Consecutive days (ending today/yesterday) with at least one deed —
  /// from [PeriodStats.currentStreak].
  final int currentStreak;

  /// All-time best streak — from [PeriodStats.bestStreak].
  final int bestStreak;

  /// All-time days at least one salah was checked off (sum of the five
  /// `salah_*` items' done-days over a wide window).
  final int salahDaysDone;

  /// All-time days the `quran` tracker was completed.
  final int quranDaysDone;

  /// All-time days the `roza` (fasting) tracker was completed.
  final int fastingDaysDone;

  /// All-time days the `tahajjud` tracker was completed.
  final int tahajjudDaysDone;

  /// All-time days the `sadaqah` tracker was completed.
  final int sadaqahDaysDone;

  /// Lifetime dhikr saved via the tasbih counter.
  final int totalDhikr;

  /// Lifetime number of saved tasbih rounds.
  final int tasbihSessions;

  /// Ayahs the user has bookmarked.
  final int quranBookmarks;

  /// Whether the reader has ever recorded a position.
  final bool hasStartedReading;
}

/// Grouping used on the screen — purely for layout/copy.
enum AchievementCategory { streaks, salah, dhikr, quran, fasting }

/// Visual tier. Higher tiers reuse the warm "celebration" palette; there is
/// no "failed" tier — locked is just not-yet.
enum AchievementTier { bronze, silver, gold }

/// A single, pure achievement definition. [threshold] is the value the
/// measured stat must reach; [measure] extracts that stat from
/// [AchievementStats] so progress can be computed generically.
final class Achievement {
  const Achievement({
    required this.id,
    required this.category,
    required this.tier,
    required this.iconKey,
    required this.threshold,
    required this.measure,
    this.group,
  });

  /// Stable id (l10n name/description keys are derived as
  /// `ach_<id>` / `ach_<id>_desc`).
  final String id;
  final AchievementCategory category;
  final AchievementTier tier;

  /// Key into [AchievementIcons.icons].
  final String iconKey;

  /// Value [measure] must reach to unlock.
  final int threshold;

  /// Pulls the measured value for this badge out of the stats.
  final int Function(AchievementStats stats) measure;

  /// Badges sharing a [group] form a tiered ladder (bronze→silver→gold);
  /// progress for a locked badge is measured against the previous tier in
  /// the same group so the ring fills smoothly. Null = standalone.
  final String? group;

  /// Pure unlock test.
  bool isUnlocked(AchievementStats stats) => measure(stats) >= threshold;
}

/// Evaluated view of one badge for the UI.
final class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.unlocked,
    required this.current,
    required this.fraction,
  });

  final Achievement achievement;
  final bool unlocked;

  /// The measured value behind this badge.
  final int current;

  /// 0..1 progress toward [Achievement.threshold]. For a tiered badge this
  /// is measured from the previous tier's threshold so each ring shows the
  /// step just for this tier; unlocked badges are always 1.
  final double fraction;
}

/// Curated, real-data-only catalog. Every [measure] reads a field that is
/// genuinely populated by [AchievementStore]. Ladders share a [group].
abstract final class AchievementCatalog {
  static int _streak(AchievementStats s) => s.bestStreak;
  static int _salah(AchievementStats s) => s.salahDaysDone;
  static int _dhikr(AchievementStats s) => s.totalDhikr;
  static int _quranDays(AchievementStats s) => s.quranDaysDone;
  static int _fasting(AchievementStats s) => s.fastingDaysDone;
  static int _measureStarted(AchievementStats s) => s.hasStartedReading ? 1 : 0;
  static int _measureBookmarks(AchievementStats s) => s.quranBookmarks;

  static const all = <Achievement>[
    // ---- Streaks ladder (best streak: 3 / 7 / 30 / 100) ----
    Achievement(
      id: 'streak_3',
      category: AchievementCategory.streaks,
      tier: AchievementTier.bronze,
      iconKey: 'spark',
      threshold: 3,
      group: 'streak',
      measure: _streak,
    ),
    Achievement(
      id: 'streak_7',
      category: AchievementCategory.streaks,
      tier: AchievementTier.bronze,
      iconKey: 'spark',
      threshold: 7,
      group: 'streak',
      measure: _streak,
    ),
    Achievement(
      id: 'streak_30',
      category: AchievementCategory.streaks,
      tier: AchievementTier.silver,
      iconKey: 'fire',
      threshold: 30,
      group: 'streak',
      measure: _streak,
    ),
    Achievement(
      id: 'streak_100',
      category: AchievementCategory.streaks,
      tier: AchievementTier.gold,
      iconKey: 'fire',
      threshold: 100,
      group: 'streak',
      measure: _streak,
    ),
    // ---- Salah consistency ladder (days a prayer was logged) ----
    Achievement(
      id: 'salah_10',
      category: AchievementCategory.salah,
      tier: AchievementTier.bronze,
      iconKey: 'mosque',
      threshold: 10,
      group: 'salah',
      measure: _salah,
    ),
    Achievement(
      id: 'salah_50',
      category: AchievementCategory.salah,
      tier: AchievementTier.silver,
      iconKey: 'mosque',
      threshold: 50,
      group: 'salah',
      measure: _salah,
    ),
    Achievement(
      id: 'salah_200',
      category: AchievementCategory.salah,
      tier: AchievementTier.gold,
      iconKey: 'mosque',
      threshold: 200,
      group: 'salah',
      measure: _salah,
    ),
    // ---- Dhikr totals ladder (100 / 1000 / 10000) ----
    Achievement(
      id: 'dhikr_100',
      category: AchievementCategory.dhikr,
      tier: AchievementTier.bronze,
      iconKey: 'beads',
      threshold: 100,
      group: 'dhikr',
      measure: _dhikr,
    ),
    Achievement(
      id: 'dhikr_1000',
      category: AchievementCategory.dhikr,
      tier: AchievementTier.silver,
      iconKey: 'beads',
      threshold: 1000,
      group: 'dhikr',
      measure: _dhikr,
    ),
    Achievement(
      id: 'dhikr_10000',
      category: AchievementCategory.dhikr,
      tier: AchievementTier.gold,
      iconKey: 'beads',
      threshold: 10000,
      group: 'dhikr',
      measure: _dhikr,
    ),
    // ---- Quran reading ----
    Achievement(
      id: 'quran_start',
      category: AchievementCategory.quran,
      tier: AchievementTier.bronze,
      iconKey: 'book',
      threshold: 1,
      measure: _measureStarted,
    ),
    Achievement(
      id: 'quran_days_7',
      category: AchievementCategory.quran,
      tier: AchievementTier.silver,
      iconKey: 'book',
      threshold: 7,
      group: 'quranDays',
      measure: _quranDays,
    ),
    Achievement(
      id: 'quran_days_30',
      category: AchievementCategory.quran,
      tier: AchievementTier.gold,
      iconKey: 'library',
      threshold: 30,
      group: 'quranDays',
      measure: _quranDays,
    ),
    Achievement(
      id: 'quran_bookmark_5',
      category: AchievementCategory.quran,
      tier: AchievementTier.bronze,
      iconKey: 'star',
      threshold: 5,
      measure: _measureBookmarks,
    ),
    // ---- Fasting ladder (roza days: 1 / 10 / 30) ----
    Achievement(
      id: 'fast_1',
      category: AchievementCategory.fasting,
      tier: AchievementTier.bronze,
      iconKey: 'sun',
      threshold: 1,
      group: 'fasting',
      measure: _fasting,
    ),
    Achievement(
      id: 'fast_10',
      category: AchievementCategory.fasting,
      tier: AchievementTier.silver,
      iconKey: 'sun',
      threshold: 10,
      group: 'fasting',
      measure: _fasting,
    ),
    Achievement(
      id: 'fast_30',
      category: AchievementCategory.fasting,
      tier: AchievementTier.gold,
      iconKey: 'moon',
      threshold: 30,
      group: 'fasting',
      measure: _fasting,
    ),
  ];

  static List<Achievement> byCategory(AchievementCategory c) =>
      [for (final a in all) if (a.category == c) a];
}

/// Pure evaluator: maps the catalog over [stats], computing unlocked state
/// and a per-tier progress fraction. No Flutter, no clock, no randomness.
abstract final class AchievementEvaluator {
  /// Lower bound of a tiered badge's progress window = the highest threshold
  /// below it within the same [Achievement.group] (else 0).
  static int _floorFor(Achievement a) {
    if (a.group == null) {
      return 0;
    }
    var floor = 0;
    for (final other in AchievementCatalog.all) {
      if (other.group == a.group &&
          other.threshold < a.threshold &&
          other.threshold > floor) {
        floor = other.threshold;
      }
    }
    return floor;
  }

  static AchievementProgress evaluateOne(
    Achievement a,
    AchievementStats stats,
  ) {
    final current = a.measure(stats);
    final unlocked = current >= a.threshold;
    final floor = _floorFor(a);
    final span = a.threshold - floor;
    final fraction = unlocked
        ? 1.0
        : span <= 0
            ? 0.0
            : ((current - floor) / span).clamp(0.0, 1.0).toDouble();
    return AchievementProgress(
      achievement: a,
      unlocked: unlocked,
      current: current,
      fraction: fraction,
    );
  }

  static List<AchievementProgress> evaluate(AchievementStats stats) =>
      [for (final a in AchievementCatalog.all) evaluateOne(a, stats)];

  /// Ids of every currently-unlocked badge (for "newly unlocked" diffing).
  static Set<String> unlockedIds(AchievementStats stats) => {
        for (final a in AchievementCatalog.all)
          if (a.isUnlocked(stats)) a.id,
      };

  static int unlockedCount(AchievementStats stats) =>
      unlockedIds(stats).length;
}
