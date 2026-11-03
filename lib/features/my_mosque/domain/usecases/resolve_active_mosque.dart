import '../entities/mosque_profile.dart';
import '../entities/mosque_schedule.dart';
import '../entities/mosque_state.dart';

/// Why a [MosqueResolution] picked its profile.
enum MosqueReason {
  /// Manual mode: the user-selected profile.
  manual,

  /// A still-valid temporary override.
  override,

  /// A matching time-of-day [MosqueRule].
  rule,

  /// A [MosqueSeason] covering today's date.
  season,

  /// The default mosque.
  defaultMosque,

  /// No rule, season or default applies: the selection / first profile.
  fallback,
}

/// Outcome of resolving which mosque is active right now.
final class MosqueResolution {
  const MosqueResolution({
    required this.mode,
    this.profile,
    this.isOverride = false,
    this.reason = MosqueReason.fallback,
    this.season,
  });

  /// The season that decided [profile] when [reason] is
  /// [MosqueReason.season]; otherwise null.
  final MosqueSeason? season;

  /// The resolved profile, or null when there are none.
  final MosqueProfile? profile;

  /// The mode the resolution was made under.
  final ScheduleMode mode;

  /// True when a temporary override is what's currently in effect.
  final bool isOverride;

  /// What decided [profile].
  final MosqueReason reason;

  bool get isAuto => mode == ScheduleMode.auto;

  @override
  bool operator ==(Object other) =>
      other is MosqueResolution &&
      other.profile == profile &&
      other.mode == mode &&
      other.isOverride == isOverride &&
      other.reason == reason &&
      other.season == season;

  @override
  int get hashCode => Object.hash(profile, mode, isOverride, reason, season);
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

/// Precedence: first matching time-of-day rule, then first season covering
/// [now]'s date (the day's base mosque), then the default, the manual
/// selection, the first profile.
(String?, MosqueReason, MosqueSeason?) _resolveAuto(
  MosqueState state,
  DateTime now,
) {
  for (final rule in state.rules) {
    if (_byId(state, rule.mosqueId) != null && rule.matches(now)) {
      return (rule.mosqueId, MosqueReason.rule, null);
    }
  }
  for (final season in state.seasons) {
    if (_byId(state, season.mosqueId) != null && season.contains(now)) {
      return (season.mosqueId, MosqueReason.season, season);
    }
  }
  if (_byId(state, state.defaultId) != null) {
    return (state.defaultId, MosqueReason.defaultMosque, null);
  }
  if (_byId(state, state.activeId) != null) {
    return (state.activeId, MosqueReason.fallback, null);
  }
  return (state.profiles.firstOrNull?.id, MosqueReason.fallback, null);
}

/// The mosque the schedule alone resolves to at [now], ignoring any override.
/// First matching rule wins; otherwise the first season covering [now]'s
/// date, then the default, the manual selection, the first profile. Null
/// only when there are no profiles.
String? resolveAutoMosqueId(MosqueState state, DateTime now) =>
    _resolveAuto(state, now).$1;

/// Resolves the mosque active on Home at [now]. In manual mode this is the
/// user-selected profile; in auto mode it's the schedule result, unless a
/// still-valid [MosqueOverride] is in effect (its baseline still matches the
/// current auto target — i.e. no window or season boundary has been crossed
/// since — and it was set today).
MosqueResolution resolveActiveMosque(MosqueState state, DateTime now) {
  if (state.mode == ScheduleMode.manual) {
    final profile =
        _byId(state, state.activeId) ??
        (state.profiles.isEmpty ? null : state.profiles.first);
    return MosqueResolution(
      mode: state.mode,
      profile: profile,
      reason: MosqueReason.manual,
    );
  }
  final (autoId, reason, season) = _resolveAuto(state, now);
  final override = state.activeOverride;
  if (override != null &&
      override.baselineAutoId == autoId &&
      override.liveAt(now, state.rules) &&
      _byId(state, override.mosqueId) != null) {
    return MosqueResolution(
      mode: state.mode,
      profile: _byId(state, override.mosqueId),
      isOverride: true,
      reason: MosqueReason.override,
    );
  }
  return MosqueResolution(
    mode: state.mode,
    profile: _byId(state, autoId),
    reason: reason,
    season: season,
  );
}
