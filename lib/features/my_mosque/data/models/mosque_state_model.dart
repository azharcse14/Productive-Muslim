import '../../../settings/domain/entities/prayer_params.dart';
import '../../domain/entities/jamaat_config.dart';
import '../../domain/entities/mosque_profile.dart';
import '../../domain/entities/mosque_schedule.dart';
import '../../domain/entities/mosque_state.dart';

/// Hand-written JSON mapping for [MosqueState] (guide §3 — no codegen).
/// Corrupt profiles and unknown entry types are skipped — never throws on
/// bad shapes so old/new payloads survive app upgrades.
abstract final class MosqueStateModel {
  static Map<String, Object?> toMap(MosqueState state) => {
        'profiles': [
          for (final profile in state.profiles)
            {
              'id': profile.id,
              'name': profile.name,
              'entries': {
                for (final e in profile.entries.entries)
                  e.key.name: switch (e.value) {
                    FixedJamaat(:final time) => {
                        'type': 'fixed',
                        'hour': time.hour,
                        'minute': time.minute,
                      },
                    OffsetJamaat(:final offset) => {
                        'type': 'offset',
                        'minutes': offset.inMinutes,
                      },
                    NoJamaat() => {'type': 'none'},
                  },
              },
            },
        ],
        'activeId': state.activeId,
        'mode': state.mode.name,
        'rules': [
          for (final rule in state.rules)
            {
              'mosqueId': rule.mosqueId,
              'days': rule.days.toList(),
              'start': {'hour': rule.start.hour, 'minute': rule.start.minute},
              'end': {'hour': rule.end.hour, 'minute': rule.end.minute},
            },
        ],
        'defaultId': state.defaultId,
        if (state.activeOverride case final o?)
          'override': {
            'mosqueId': o.mosqueId,
            'baselineAutoId': o.baselineAutoId,
          },
      };

  static MosqueState fromMap(Map<String, Object?> map) {
    final rawProfiles = map['profiles'];
    final rawRules = map['rules'];
    return MosqueState(
      profiles: [
        if (rawProfiles is List)
          for (final raw in rawProfiles)
            if (_profile(raw) case final MosqueProfile profile) profile,
      ],
      activeId: map['activeId'] as String?,
      mode: map['mode'] == 'auto' ? ScheduleMode.auto : ScheduleMode.manual,
      rules: [
        if (rawRules is List)
          for (final raw in rawRules)
            if (_rule(raw) case final MosqueRule rule) rule,
      ],
      defaultId: map['defaultId'] as String?,
      activeOverride: _override(map['override']),
    );
  }

  /// Null when the rule shape is unusable (missing mosqueId / times).
  static MosqueRule? _rule(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, Object?>();
    final mosqueId = map['mosqueId'];
    final start = _clock(map['start']);
    final end = _clock(map['end']);
    if (mosqueId is! String || start == null || end == null) {
      return null;
    }
    return MosqueRule(
      mosqueId: mosqueId,
      start: start,
      end: end,
      days: {
        if (map['days'] is List)
          for (final d in map['days']! as List)
            if (d is int && d >= 1 && d <= 7) d,
      },
    );
  }

  static ClockTime? _clock(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, Object?>();
    final hour = map['hour'];
    final minute = map['minute'];
    if (hour is! int ||
        minute is! int ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return ClockTime(hour, minute);
  }

  static MosqueOverride? _override(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, Object?>();
    final mosqueId = map['mosqueId'];
    if (mosqueId is! String) {
      return null;
    }
    return MosqueOverride(
      mosqueId: mosqueId,
      baselineAutoId: map['baselineAutoId'] as String?,
    );
  }

  /// Null when the profile shape is unusable (missing id/name).
  static MosqueProfile? _profile(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, Object?>();
    final id = map['id'];
    final name = map['name'];
    if (id is! String || name is! String) {
      return null;
    }
    final rawEntries = (map['entries'] as Map?)?.cast<String, Object?>() ?? {};
    return MosqueProfile(
      id: id,
      name: name,
      entries: {
        for (final prayer in Prayer.values)
          if (_entry(rawEntries[prayer.name]) case final JamaatEntry entry)
            prayer: entry,
      },
    );
  }

  /// Null for unknown/corrupt entry shapes (treated as unset).
  static JamaatEntry? _entry(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, Object?>();
    switch (map['type']) {
      case 'fixed':
        final hour = map['hour'];
        final minute = map['minute'];
        if (hour is! int ||
            minute is! int ||
            hour < 0 ||
            hour > 23 ||
            minute < 0 ||
            minute > 59) {
          return null;
        }
        return FixedJamaat(ClockTime(hour, minute));
      case 'offset':
        final minutes = map['minutes'];
        if (minutes is! int) {
          return null;
        }
        return OffsetJamaat(Duration(minutes: minutes));
      case 'none':
        return const NoJamaat();
      default:
        return null;
    }
  }
}
