import 'package:signals_flutter/signals_flutter.dart';

import '../../../settings/domain/entities/prayer_params.dart';
import '../../domain/entities/jamaat_config.dart';
import '../../domain/entities/mosque_profile.dart';
import '../../domain/entities/mosque_state.dart';
import '../../domain/usecases/get_mosque_state.dart';
import '../../domain/usecases/save_mosque_state.dart';

/// App-scoped jamaat/mosque state. The active profile's [JamaatConfig]
/// drives the Home countdown and jamaat reminders.
final class MosqueStore {
  MosqueStore(this._get, this._save);

  final GetMosqueState _get;
  final SaveMosqueState _save;

  late final state = signal(const MosqueState());
  late final activeProfile = computed(() => state.value.active);
  late final activeConfig = computed(() => state.value.activeConfig);

  var _idCounter = 0;

  Future<void> load() async {
    final result = await _get();
    result.fold((value) => state.value = value, (_) {});
    _idCounter = state.value.profiles.length;
  }

  /// Adds a profile (Maghrib defaults to offset +5) and makes it active.
  Future<MosqueProfile> addProfile(String name) async {
    final profile = MosqueProfile.create(
      id: 'mosque_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}',
      name: name,
    );
    await _update(
      state.value.copyWith(
        profiles: [...state.value.profiles, profile],
        activeId: profile.id,
      ),
    );
    return profile;
  }

  Future<void> setActive(String id) =>
      _update(state.value.copyWith(activeId: id));

  Future<void> renameProfile(String id, String name) => _mapProfile(
        id,
        (p) => p.copyWith(name: name),
      );

  Future<void> setEntry(String id, Prayer prayer, JamaatEntry entry) =>
      _mapProfile(
        id,
        (p) => p.copyWith(entries: {...p.entries, prayer: entry}),
      );

  Future<void> deleteProfile(String id) async {
    final remaining =
        state.value.profiles.where((p) => p.id != id).toList();
    await _update(
      MosqueState(
        profiles: remaining,
        activeId: state.value.activeId == id
            ? (remaining.isEmpty ? null : remaining.first.id)
            : state.value.activeId,
      ),
    );
  }

  Future<void> _mapProfile(
    String id,
    MosqueProfile Function(MosqueProfile) transform,
  ) =>
      _update(
        state.value.copyWith(
          profiles: [
            for (final p in state.value.profiles)
              if (p.id == id) transform(p) else p,
          ],
        ),
      );

  Future<void> _update(MosqueState next) async {
    state.value = next;
    await _save(next);
  }
}
