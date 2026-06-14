import 'package:signals_flutter/signals_flutter.dart';

import '../../../settings/domain/entities/prayer_params.dart';
import '../../domain/entities/jamaat_config.dart';
import '../../domain/entities/mosque_profile.dart';
import '../../domain/entities/mosque_schedule.dart';
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

  /// Auto/manual switch mode and the auto-switch rules.
  late final mode = computed(() => state.value.mode);
  late final rules = computed(() => state.value.rules);

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

  /// Switches between manual selection and the auto schedule. Leaving auto
  /// clears any temporary override.
  Future<void> setMode(ScheduleMode mode) => _update(
        state.value
            .copyWith(mode: mode)
            .withOverride(mode == ScheduleMode.auto ? state.value.activeOverride : null),
      );

  Future<void> addRule(MosqueRule rule) =>
      _update(state.value.copyWith(rules: [...state.value.rules, rule]));

  Future<void> updateRule(int index, MosqueRule rule) {
    final rules = state.value.rules;
    if (index < 0 || index >= rules.length) {
      return Future.value();
    }
    return _update(
      state.value.copyWith(
        rules: [
          for (final (i, r) in rules.indexed) if (i == index) rule else r,
        ],
      ),
    );
  }

  Future<void> removeRule(int index) {
    final rules = state.value.rules;
    if (index < 0 || index >= rules.length) {
      return Future.value();
    }
    return _update(
      state.value.copyWith(
        rules: [
          for (final (i, r) in rules.indexed) if (i != index) r,
        ],
      ),
    );
  }

  Future<void> setDefaultMosque(String? id) =>
      _update(state.value.withDefault(id));

  /// Sets a temporary override (auto mode). [baselineAutoId] is the schedule's
  /// current target, so the override expires once a window boundary is crossed.
  Future<void> setOverride(String mosqueId, String? baselineAutoId) => _update(
        state.value.withOverride(
          MosqueOverride(mosqueId: mosqueId, baselineAutoId: baselineAutoId),
        ),
      );

  Future<void> clearOverride() => _update(state.value.withOverride(null));

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
    final current = state.value;
    final remaining = current.profiles.where((p) => p.id != id).toList();
    final override = current.activeOverride;
    await _update(
      MosqueState(
        profiles: remaining,
        activeId: current.activeId == id
            ? (remaining.isEmpty ? null : remaining.first.id)
            : current.activeId,
        mode: current.mode,
        // Drop any rules pointing at the removed profile.
        rules: [
          for (final r in current.rules)
            if (r.mosqueId != id) r,
        ],
        defaultId: current.defaultId == id ? null : current.defaultId,
        activeOverride: override?.mosqueId == id ? null : override,
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
