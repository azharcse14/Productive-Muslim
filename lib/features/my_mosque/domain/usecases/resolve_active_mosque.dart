import '../entities/mosque_profile.dart';
import '../entities/mosque_schedule.dart';
import '../entities/mosque_state.dart';

/// Outcome of resolving which mosque is active right now.
final class MosqueResolution {
  const MosqueResolution({
    required this.mode,
    this.profile,
    this.isOverride = false,
  });

  /// The resolved profile, or null when there are none.
  final MosqueProfile? profile;

  /// The mode the resolution was made under.
  final ScheduleMode mode;

  /// True when a temporary override is what's currently in effect.
  final bool isOverride;

  bool get isAuto => mode == ScheduleMode.auto;

  @override
  bool operator ==(Object other) =>
      other is MosqueResolution &&
      other.profile == profile &&
      other.mode == mode &&
      other.isOverride == isOverride;

  @override
  int get hashCode => Object.hash(profile, mode, isOverride);
}

MosqueProfile? _byId(MosqueState state, String? id) {
  if (id == null) {
    return null;
  }
  for (final profile in state.profiles) {
    if (profile.id == id) {
      return profile;
    }
  }
  return null;
}

/// The mosque the schedule alone resolves to at [now], ignoring any override.
/// First matching rule wins; otherwise the default, then the manual selection,
/// then the first profile. Null only when there are no profiles.
String? resolveAutoMosqueId(MosqueState state, DateTime now) {
  for (final rule in state.rules) {
    if (_byId(state, rule.mosqueId) != null && rule.matches(now)) {
      return rule.mosqueId;
    }
  }
  if (_byId(state, state.defaultId) != null) {
    return state.defaultId;
  }
  if (_byId(state, state.activeId) != null) {
    return state.activeId;
  }
  return state.profiles.isEmpty ? null : state.profiles.first.id;
}

/// Resolves the mosque active on Home at [now]. In manual mode this is the
/// user-selected profile; in auto mode it's the schedule result, unless a
/// still-valid [MosqueOverride] is in effect (its baseline still matches the
/// current auto target — i.e. no window boundary has been crossed since —
/// and it was set today).
MosqueResolution resolveActiveMosque(MosqueState state, DateTime now) {
  if (state.mode == ScheduleMode.manual) {
    final profile =
        _byId(state, state.activeId) ??
        (state.profiles.isEmpty ? null : state.profiles.first);
    return MosqueResolution(mode: state.mode, profile: profile);
  }
  final autoId = resolveAutoMosqueId(state, now);
  final override = state.activeOverride;
  if (override != null &&
      override.baselineAutoId == autoId &&
      override.liveAt(now) &&
      _byId(state, override.mosqueId) != null) {
    return MosqueResolution(
      mode: state.mode,
      profile: _byId(state, override.mosqueId),
      isOverride: true,
    );
  }
  return MosqueResolution(mode: state.mode, profile: _byId(state, autoId));
}
