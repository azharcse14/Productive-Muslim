/// Input style of a tracker (design §4.7 — three types rendered
/// distinctly).
///
/// Persisted in the muhasaba DB — never change or reuse a code; append new
/// kinds.
enum TrackerKind {
  yesNo(0),
  count(1),
  duration(2);

  const TrackerKind(this.code);

  /// Stable value stored in `tracker_items.kind`.
  final int code;

  /// The kind stored as [code], or null for an unknown code.
  static TrackerKind? fromCode(int code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// One muhasaba tracker definition. Items are ARCHIVED, never deleted —
/// history is preserved (hard product rule).
final class TrackerItem {
  const TrackerItem({
    required this.id,
    required this.name,
    required this.kind,
    this.dailyTarget,
    this.icon = 'spark',
    this.colorIndex = 0,
    this.isDefault = false,
    this.archived = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final TrackerKind kind;

  /// Count: repetitions; duration: minutes. Null = any value counts.
  final int? dailyTarget;

  /// Key into the curated icon set (presentation maps to IconData).
  final String icon;

  /// Index into the curated color palette.
  final int colorIndex;

  /// Seeded defaults can be archived but not edited structurally.
  final bool isDefault;
  final bool archived;
  final int sortOrder;

  /// Whether [value] completes this item for a day.
  bool isDone(int value) => switch (dailyTarget) {
    null => value > 0,
    final target when target <= 0 => value > 0,
    final target => value >= target,
  };

  /// 0..1 progress of [value] toward completion.
  double fractionOf(int value) => switch (dailyTarget) {
    null => value > 0 ? 1 : 0,
    final target when target <= 0 => value > 0 ? 1 : 0,
    final target => (value / target).clamp(0, 1).toDouble(),
  };

  TrackerItem copyWith({
    String? name,
    TrackerKind? kind,
    int? Function()? dailyTarget,
    String? icon,
    int? colorIndex,
    bool? archived,
    int? sortOrder,
  }) {
    return TrackerItem(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      dailyTarget: dailyTarget == null ? this.dailyTarget : dailyTarget(),
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      isDefault: isDefault,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrackerItem &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.dailyTarget == dailyTarget &&
      other.icon == icon &&
      other.colorIndex == colorIndex &&
      other.isDefault == isDefault &&
      other.archived == archived &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    dailyTarget,
    icon,
    colorIndex,
    isDefault,
    archived,
    sortOrder,
  );
}

/// Seeded default items (design §4.7). Names are l10n KEYS resolved in
/// presentation; ids are stable forever (entries reference them).
abstract final class DefaultTrackers {
  static const salahIds = [
    'salah_fajr',
    'salah_dhuhr',
    'salah_asr',
    'salah_maghrib',
    'salah_isha',
  ];

  static List<TrackerItem> items() => [
    for (final (i, id) in salahIds.indexed)
      TrackerItem(
        id: id,
        name: id,
        kind: TrackerKind.yesNo,
        icon: 'mosque',
        isDefault: true,
        sortOrder: i,
      ),
    const TrackerItem(
      id: 'quran',
      name: 'quran',
      kind: TrackerKind.duration,
      dailyTarget: 10,
      icon: 'book',
      colorIndex: 1,
      isDefault: true,
      sortOrder: 5,
    ),
    const TrackerItem(
      id: 'azkar',
      name: 'azkar',
      kind: TrackerKind.count,
      dailyTarget: 100,
      icon: 'beads',
      colorIndex: 2,
      isDefault: true,
      sortOrder: 6,
    ),
    const TrackerItem(
      id: 'sadaqah',
      name: 'sadaqah',
      kind: TrackerKind.yesNo,
      icon: 'heart',
      colorIndex: 3,
      isDefault: true,
      sortOrder: 7,
    ),
    const TrackerItem(
      id: 'tahajjud',
      name: 'tahajjud',
      kind: TrackerKind.yesNo,
      icon: 'moon',
      colorIndex: 4,
      isDefault: true,
      sortOrder: 8,
    ),
    const TrackerItem(
      id: 'roza',
      name: 'roza',
      kind: TrackerKind.yesNo,
      icon: 'sun',
      colorIndex: 5,
      isDefault: true,
      sortOrder: 9,
    ),
    ...health,
  ];

  /// Sunnah-guided health habits, also shown on the Health screen.
  static const healthIds = ['water', 'sleep', 'exercise', 'miswak'];

  static const health = [
    // Moderate drinking through the day, in three breaths (Muslim 2028).
    TrackerItem(
      id: 'water',
      name: 'water',
      kind: TrackerKind.count,
      dailyTarget: 8,
      icon: 'water',
      isDefault: true,
      sortOrder: 10,
    ),
    // Early to bed after Isha, up for Fajr (Bukhari 568).
    TrackerItem(
      id: 'sleep',
      name: 'sleep',
      kind: TrackerKind.duration,
      dailyTarget: 420,
      icon: 'bed',
      colorIndex: 4,
      isDefault: true,
      sortOrder: 11,
    ),
    // "The strong believer is better…" (Muslim 2664).
    TrackerItem(
      id: 'exercise',
      name: 'exercise',
      kind: TrackerKind.duration,
      dailyTarget: 30,
      icon: 'walk',
      colorIndex: 2,
      isDefault: true,
      sortOrder: 12,
    ),
    // Siwak before prayers (Bukhari 887).
    TrackerItem(
      id: 'miswak',
      name: 'miswak',
      kind: TrackerKind.yesNo,
      colorIndex: 1,
      isDefault: true,
      sortOrder: 13,
    ),
  ];
}
