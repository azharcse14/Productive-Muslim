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
  /// An overnight window (e.g. Fri 20:00–02:00) belongs to the day it
  /// starts on, so Saturday 00:30 still matches a Friday rule.
  bool matches(DateTime now) {
    if (allDay) {
      return _on(now.weekday);
    }
    final mins = now.hour * 60 + now.minute;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (s <= e) {
      return _on(now.weekday) && mins >= s && mins < e;
    }
    return (mins >= s && _on(now.weekday)) || spillsOver(now);
  }

  /// Whether [now] is in the after-midnight tail of an overnight window
  /// that started the day before (Sat 00:30 for a Fri 20:00–02:00 rule).
  bool spillsOver(DateTime now) {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    final yesterday = now.weekday == DateTime.monday ? 7 : now.weekday - 1;
    return s > e && now.hour * 60 + now.minute < e && _on(yesterday);
  }

  bool _on(int weekday) => days.isEmpty || days.contains(weekday);

  MosqueRule copyWith({
    String? mosqueId,
    Set<int>? days,
    ClockTime? start,
    ClockTime? end,
  }) => MosqueRule(
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
/// the override is treated as expired and auto resumes. It also lapses at the
/// end of [setOn] (the wall-clock day it was set), so a schedule that keeps
/// resolving to the same mosque can't pin it for days.
final class MosqueOverride {
  const MosqueOverride({
    required this.mosqueId,
    this.baselineAutoId,
    this.setOn,
  });

  final String mosqueId;
  final String? baselineAutoId;

  /// y/m/d the override was set. Null for overrides persisted before this
  /// field existed — of unknown age, so treated as expired.
  final DateTime? setOn;

  /// Whether the override is still within its day at [now]. Like an
  /// overnight rule, that day runs on past midnight while one of [rules]
  /// spills over from it, so a Fri 23:30 override survives Sat 00:30.
  bool liveAt(DateTime now, [List<MosqueRule> rules = const []]) {
    final day = setOn;
    if (day == null) {
      return false;
    }
    bool isOn(DateTime d) =>
        day.year == d.year && day.month == d.month && day.day == d.day;
    return isOn(now) ||
        (isOn(DateTime(now.year, now.month, now.day - 1)) &&
            rules.any((r) => r.spillsOver(now)));
  }

  @override
  bool operator ==(Object other) =>
      other is MosqueOverride &&
      other.mosqueId == mosqueId &&
      other.baselineAutoId == baselineAutoId &&
      other.setOn == setOn;

  @override
  int get hashCode => Object.hash(mosqueId, baselineAutoId, setOn);
}
