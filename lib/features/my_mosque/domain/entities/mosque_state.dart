import 'jamaat_config.dart';
import 'mosque_profile.dart';
import 'mosque_schedule.dart';

/// All saved mosque profiles plus how the active one is chosen (design §4.9):
/// a manual selection, or an auto schedule of [rules] with a [defaultId]
/// fallback and an optional temporary [activeOverride].
final class MosqueState {
  const MosqueState({
    this.profiles = const [],
    this.activeId,
    this.mode = ScheduleMode.manual,
    this.rules = const [],
    this.defaultId,
    this.activeOverride,
  });

  final List<MosqueProfile> profiles;

  /// Id of the manually-selected profile (also the one being edited), or null.
  final String? activeId;

  /// How the active mosque is resolved on Home.
  final ScheduleMode mode;

  /// Ordered auto-switch rules (first match wins) — used in [ScheduleMode.auto].
  final List<MosqueRule> rules;

  /// Fallback mosque when no rule matches (auto mode).
  final String? defaultId;

  /// Temporary manual override while in auto mode.
  final MosqueOverride? activeOverride;

  /// The manually-selected profile; null when [activeId] is null. A stale
  /// [activeId] (profile gone) falls back to the first profile, so the
  /// editor and reminders never go blank while mosques exist.
  MosqueProfile? get active {
    if (activeId == null) {
      return null;
    }
    for (final profile in profiles) {
      if (profile.id == activeId) {
        return profile;
      }
    }
    return profiles.firstOrNull;
  }

  /// Jamaat config of the manually-selected profile; [JamaatConfig.none] when
  /// absent. (Home uses the schedule resolver; this stays for the editor and
  /// the notification plan.)
  JamaatConfig get activeConfig => active?.config ?? JamaatConfig.none;

  /// [activeId] is preserved unless explicitly passed — use [withActive]
  /// to clear it (a `String?` parameter cannot distinguish "omit" from
  /// "set null").
  MosqueState copyWith({
    List<MosqueProfile>? profiles,
    String? activeId,
    ScheduleMode? mode,
    List<MosqueRule>? rules,
  }) => MosqueState(
    profiles: profiles ?? this.profiles,
    activeId: activeId ?? this.activeId,
    mode: mode ?? this.mode,
    rules: rules ?? this.rules,
    defaultId: defaultId,
    activeOverride: activeOverride,
  );

  /// Returns a copy with [activeId] set to [id] (null deselects).
  MosqueState withActive(String? id) => MosqueState(
    profiles: profiles,
    activeId: id,
    mode: mode,
    rules: rules,
    defaultId: defaultId,
    activeOverride: activeOverride,
  );

  /// Returns a copy with [defaultId] set to [id] (null clears).
  MosqueState withDefault(String? id) => MosqueState(
    profiles: profiles,
    activeId: activeId,
    mode: mode,
    rules: rules,
    defaultId: id,
    activeOverride: activeOverride,
  );

  /// Returns a copy with the [activeOverride] set (null clears it).
  MosqueState withOverride(MosqueOverride? value) => MosqueState(
    profiles: profiles,
    activeId: activeId,
    mode: mode,
    rules: rules,
    defaultId: defaultId,
    activeOverride: value,
  );

  @override
  bool operator ==(Object other) {
    if (other is! MosqueState ||
        other.activeId != activeId ||
        other.mode != mode ||
        other.defaultId != defaultId ||
        other.activeOverride != activeOverride ||
        other.profiles.length != profiles.length ||
        other.rules.length != rules.length) {
      return false;
    }
    for (var i = 0; i < profiles.length; i++) {
      if (other.profiles[i] != profiles[i]) {
        return false;
      }
    }
    for (var i = 0; i < rules.length; i++) {
      if (other.rules[i] != rules[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    activeId,
    mode,
    defaultId,
    activeOverride,
    Object.hashAll(profiles),
    Object.hashAll(rules),
  );
}
