import 'jamaat_config.dart';

/// How the active mosque is chosen on Home (design §4.9 follow-up):
/// [manual] = the user-picked profile; [auto] = resolved from [MosqueRule]s.
enum ScheduleMode { manual, auto }

/// One auto-switch rule: when the clock falls on one of [days] within the
/// [start]–[end] window, mosque [mosqueId] becomes active. Rules are evaluated
/// in order and the first match wins. Pure Dart (no Flutter).
final class MosqueRule {
  const MosqueRule({
    required this.mosqueId,
    required this.start,
    required this.end,
    this.days = const {},
  });

  final String mosqueId;

  /// ISO weekdays the rule applies to (1 = Mon … 7 = Sun). Empty = every day.
  final Set<int> days;

  /// Inclusive start, exclusive end. [start] == [end] means "all day".
  final ClockTime start;
  final ClockTime end;

  bool get allDay => start == end;

  /// Whether [now] (its weekday + time-of-day) falls inside this rule.
  bool matches(DateTime now) {
    if (days.isNotEmpty && !days.contains(now.weekday)) {
      return false;
    }
    if (allDay) {
      return true;
    }
    final mins = now.hour * 60 + now.minute;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return s <= e ? (mins >= s && mins < e) : (mins >= s || mins < e);
  }

  MosqueRule copyWith({
    String? mosqueId,
    Set<int>? days,
    ClockTime? start,
    ClockTime? end,
  }) =>
      MosqueRule(
        mosqueId: mosqueId ?? this.mosqueId,
        days: days ?? this.days,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  @override
  bool operator ==(Object other) =>
      other is MosqueRule &&
      other.mosqueId == mosqueId &&
      other.start == start &&
      other.end == end &&
      other.days.length == days.length &&
      other.days.containsAll(days);

  @override
  int get hashCode =>
      Object.hash(mosqueId, start, end, Object.hashAllUnordered(days));
}

/// A temporary manual override while in [ScheduleMode.auto]. [baselineAutoId]
/// is the auto-resolved mosque at the moment the override was set; once the
/// schedule would resolve to a different mosque (a window boundary is crossed)
/// the override is treated as expired and auto resumes.
final class MosqueOverride {
  const MosqueOverride({required this.mosqueId, this.baselineAutoId});

  final String mosqueId;
  final String? baselineAutoId;

  @override
  bool operator ==(Object other) =>
      other is MosqueOverride &&
      other.mosqueId == mosqueId &&
      other.baselineAutoId == baselineAutoId;

  @override
  int get hashCode => Object.hash(mosqueId, baselineAutoId);
}
