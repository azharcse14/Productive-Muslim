import 'jamaat_config.dart';
import 'mosque_profile.dart';

/// All saved mosque profiles plus which one is active (design §4.9).
final class MosqueState {
  const MosqueState({this.profiles = const [], this.activeId});

  final List<MosqueProfile> profiles;

  /// Id of the active profile, or null when none is selected.
  final String? activeId;

  /// The active profile, or null when [activeId] is null or stale
  /// (e.g. the profile was deleted).
  MosqueProfile? get active {
    for (final profile in profiles) {
      if (profile.id == activeId) {
        return profile;
      }
    }
    return null;
  }

  /// Jamaat config of the active profile; [JamaatConfig.none] when absent.
  JamaatConfig get activeConfig => active?.config ?? JamaatConfig.none;

  /// [activeId] is preserved unless explicitly passed — use [withActive]
  /// to clear it (a `String?` parameter cannot distinguish "omit" from
  /// "set null").
  MosqueState copyWith({List<MosqueProfile>? profiles, String? activeId}) =>
      MosqueState(
        profiles: profiles ?? this.profiles,
        activeId: activeId ?? this.activeId,
      );

  /// Returns a copy with [activeId] set to [id] (null deselects).
  MosqueState withActive(String? id) =>
      MosqueState(profiles: profiles, activeId: id);

  @override
  bool operator ==(Object other) {
    if (other is! MosqueState ||
        other.activeId != activeId ||
        other.profiles.length != profiles.length) {
      return false;
    }
    for (var i = 0; i < profiles.length; i++) {
      if (other.profiles[i] != profiles[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(activeId, Object.hashAll(profiles));
}
