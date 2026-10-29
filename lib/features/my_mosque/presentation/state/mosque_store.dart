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

  /// Storage couldn't be read: [state] holds defaults, not the user's data,
  /// so saving it would clobber whatever is stored (mirrors SettingsStore).
  bool _readFailed = false;

  Future<void> load() async {
    final result = await _get();
    result.fold((value) {
      _readFailed = false;
      state.value = value;
    }, (_) => _readFailed = true);
    _idCounter = state.value.profiles.length;
  }

  /// Adds a profile (Maghrib defaults to offset +5) and makes it active.
  Future<MosqueProfile> addProfile(String name) async {
    final profile = MosqueProfile.create(
      id: 'mosque_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}',
      name: name,
    );
    await _update(
      (s) =>
          s.copyWith(profiles: [...s.profiles, profile], activeId: profile.id),
    );
    return profile;
  }

  Future<void> setActive(String id) => _update((s) => s.copyWith(activeId: id));

  /// Switches between manual selection and the auto schedule. Leaving auto
  /// clears any temporary override.
  Future<void> setMode(ScheduleMode mode) => _update(
    (s) => s
        .copyWith(mode: mode)
        .withOverride(mode == ScheduleMode.auto ? s.activeOverride : null),
  );

  Future<void> addRule(MosqueRule rule) =>
      _update((s) => s.copyWith(rules: [...s.rules, rule]));

  /// Puts [rule] back at [index] (undo of [removeRule]).
  Future<void> insertRule(int index, MosqueRule rule) => _update((s) {
    final rules = [...s.rules];
    rules.insert(index.clamp(0, rules.length), rule);
    return s.copyWith(rules: rules);
  });

  Future<void> updateRule(int index, MosqueRule rule) {
    if (index < 0 || index >= state.value.rules.length) {
      return Future.value();
    }
    return _update(
      (s) => s.copyWith(
        rules: [
          for (final (i, r) in s.rules.indexed)
            if (i == index) rule else r,
        ],
      ),
    );
  }

  Future<void> removeRule(int index) {
    if (index < 0 || index >= state.value.rules.length) {
      return Future.value();
    }
    return _update(
      (s) => s.copyWith(
        rules: [
          for (final (i, r) in s.rules.indexed)
            if (i != index) r,
        ],
      ),
    );
  }

  Future<void> setDefaultMosque(String? id) =>
      _update((s) => s.withDefault(id));

  /// Sets a temporary override (auto mode). [baselineAutoId] is the schedule's
  /// current target, so the override expires once a window boundary is crossed
  /// or the wall-clock day of [now] ends.
  Future<void> setOverride(
    String mosqueId,
    String? baselineAutoId,
    DateTime now,
  ) => _update(
    (s) => s.withOverride(
      MosqueOverride(
        mosqueId: mosqueId,
        baselineAutoId: baselineAutoId,
        setOn: DateTime(now.year, now.month, now.day),
      ),
    ),
  );

  Future<void> clearOverride() => _update((s) => s.withOverride(null));

  Future<void> renameProfile(String id, String name) =>
      _mapProfile(id, (p) => p.copyWith(name: name));

  Future<void> setEntry(String id, Prayer prayer, JamaatEntry entry) =>
      _mapProfile(
        id,
        (p) => p.copyWith(entries: {...p.entries, prayer: entry}),
      );

  /// Sets (or with null clears) the profile's Friday Jumu'ah time.
  Future<void> setJumuah(String id, ClockTime? time) => _mapProfile(
    id,
    (p) => p.copyWith(jumuah: time, clearJumuah: time == null),
  );

  Future<void> deleteProfile(String id) => _update((current) {
    final remaining = current.profiles.where((p) => p.id != id).toList();
    final override = current.activeOverride;
    return MosqueState(
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
    );
  });

  Future<void> _mapProfile(
    String id,
    MosqueProfile Function(MosqueProfile) transform,
  ) => _update(
    (s) => s.copyWith(
      profiles: [
        for (final p in s.profiles)
          if (p.id == id) transform(p) else p,
      ],
    ),
  );

  /// Applies [change] and saves. A function, not a value, so a change made
  /// while storage was unreadable replays onto the real state once it loads.
  Future<void> _update(MosqueState Function(MosqueState) change) async {
    if (_readFailed) {
      await load();
      if (_readFailed) {
        // ponytail: still unreadable — saving would overwrite the stored
        // mosques with defaults, so the change is in memory only.
        state.value = change(state.value);
        return;
      }
    }
    final next = change(state.value);
    state.value = next;
    await _save(next);
  }
}
