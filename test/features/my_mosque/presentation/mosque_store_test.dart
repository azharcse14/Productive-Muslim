import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:qalbee/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:qalbee/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:qalbee/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:qalbee/features/settings/domain/entities/prayer_params.dart';

import '../../../helpers/mosque_fakes.dart';

void main() {
  group('MosqueStore', () {
    test('load pulls persisted state', () async {
      const profile = MosqueProfile(id: 'a', name: 'Home');
      final (store, _) = await makeMosqueStore(
        const MosqueState(profiles: [profile], activeId: 'a'),
      );
      expect(store.activeProfile.value, profile);
    });

    test('addProfile activates it and applies the Maghrib +5 default',
        () async {
      final (store, repo) = await makeMosqueStore();
      final profile = await store.addProfile('Work');
      expect(store.state.value.activeId, profile.id);
      expect(
        profile.entries[Prayer.maghrib],
        const OffsetJamaat(Duration(minutes: 5)),
      );
      expect(repo.saves, 1);
    });

    test('setEntry updates only the targeted profile/prayer', () async {
      final (store, repo) = await makeMosqueStore();
      final a = await store.addProfile('A');
      final b = await store.addProfile('B');
      await store.setEntry(a.id, Prayer.fajr, const FixedJamaat(ClockTime(5, 0)));
      final updatedA =
          repo.stored.profiles.firstWhere((p) => p.id == a.id);
      final updatedB =
          repo.stored.profiles.firstWhere((p) => p.id == b.id);
      expect(updatedA.entries[Prayer.fajr], const FixedJamaat(ClockTime(5, 0)));
      expect(updatedB.entries[Prayer.fajr], isNull);
    });

    test('activeConfig flows from the active profile', () async {
      final (store, _) = await makeMosqueStore();
      final a = await store.addProfile('A');
      await store.setEntry(
        a.id,
        Prayer.dhuhr,
        const OffsetJamaat(Duration(minutes: 20)),
      );
      final config = store.activeConfig.value;
      expect(
        config.timeFor(Prayer.dhuhr, DateTime(2026, 6, 12, 12)),
        DateTime(2026, 6, 12, 12, 20),
      );
    });

    test('switching active profile switches the config', () async {
      final (store, _) = await makeMosqueStore();
      final a = await store.addProfile('A');
      final b = await store.addProfile('B'); // b is now active
      await store.setEntry(a.id, Prayer.isha, const FixedJamaat(ClockTime(21, 0)));
      expect(
        store.activeConfig.value.timeFor(Prayer.isha, DateTime(2026, 6, 12, 20)),
        isNull,
        reason: 'B has no isha entry',
      );
      await store.setActive(a.id);
      expect(
        store.activeConfig.value.timeFor(Prayer.isha, DateTime(2026, 6, 12, 20)),
        DateTime(2026, 6, 12, 21),
      );
      expect(b.id, isNot(a.id));
    });

    test('deleteProfile falls back to the first remaining profile',
        () async {
      final (store, _) = await makeMosqueStore();
      final a = await store.addProfile('A');
      final b = await store.addProfile('B'); // active
      await store.deleteProfile(b.id);
      expect(store.state.value.activeId, a.id);
      await store.deleteProfile(a.id);
      expect(store.state.value.activeId, isNull);
      expect(store.activeConfig.value.entries, isEmpty);
    });

    test('setMode toggles auto and clears override on leaving auto', () async {
      final (store, _) = await makeMosqueStore();
      final a = await store.addProfile('A');
      await store.setMode(ScheduleMode.auto);
      await store.setOverride(a.id, null);
      expect(store.state.value.activeOverride, isNotNull);
      await store.setMode(ScheduleMode.manual);
      expect(store.state.value.mode, ScheduleMode.manual);
      expect(store.state.value.activeOverride, isNull);
    });

    test('add/update/remove rule mutate the ordered rules list', () async {
      final (store, _) = await makeMosqueStore();
      final a = await store.addProfile('A');
      await store.addRule(
        MosqueRule(
          mosqueId: a.id,
          start: const ClockTime(10, 0),
          end: const ClockTime(18, 0),
        ),
      );
      expect(store.rules.value.single.mosqueId, a.id);
      await store.updateRule(
        0,
        store.rules.value.first.copyWith(days: {1, 2}),
      );
      expect(store.rules.value.single.days, {1, 2});
      await store.removeRule(0);
      expect(store.rules.value, isEmpty);
    });

    test('deleteProfile strips rules, default and override referencing it',
        () async {
      final (store, _) = await makeMosqueStore();
      final a = await store.addProfile('A');
      final b = await store.addProfile('B');
      await store.setMode(ScheduleMode.auto);
      await store.addRule(
        MosqueRule(
          mosqueId: b.id,
          start: const ClockTime(0, 0),
          end: const ClockTime(0, 0),
        ),
      );
      await store.setDefaultMosque(b.id);
      await store.setOverride(b.id, a.id);
      await store.deleteProfile(b.id);
      expect(store.rules.value, isEmpty);
      expect(store.state.value.defaultId, isNull);
      expect(store.state.value.activeOverride, isNull);
    });

    test('renameProfile keeps entries', () async {
      final (store, repo) = await makeMosqueStore();
      final a = await store.addProfile('Old');
      await store.renameProfile(a.id, 'New');
      final renamed = repo.stored.profiles.single;
      expect(renamed.name, 'New');
      expect(renamed.entries[Prayer.maghrib], isA<OffsetJamaat>());
    });
  });
}
