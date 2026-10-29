import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

void main() {
  group('MosqueProfile', () {
    test('create defaults Maghrib to offset +5 minutes', () {
      final profile = MosqueProfile.create(id: 'p1', name: 'Home');
      expect(profile.id, 'p1');
      expect(profile.name, 'Home');
      expect(profile.entries, {
        Prayer.maghrib: const OffsetJamaat(Duration(minutes: 5)),
      });
    });

    test('config wraps entries', () {
      const entries = <Prayer, JamaatEntry>{
        Prayer.fajr: FixedJamaat(ClockTime(5, 30)),
        Prayer.isha: NoJamaat(),
      };
      const profile = MosqueProfile(id: 'p1', name: 'Home', entries: entries);
      expect(profile.config.entries, entries);
      expect(
        profile.config.timeFor(Prayer.fajr, DateTime(2026, 6, 12, 4)),
        DateTime(2026, 6, 12, 5, 30),
      );
    });

    test('copyWith replaces fields and keeps id', () {
      final profile = MosqueProfile.create(id: 'p1', name: 'Home');
      final renamed = profile.copyWith(name: 'Work');
      expect(renamed.id, 'p1');
      expect(renamed.name, 'Work');
      expect(renamed.entries, profile.entries);

      final reconfigured = profile.copyWith(
        entries: const {Prayer.fajr: NoJamaat()},
      );
      expect(reconfigured.name, 'Home');
      expect(reconfigured.entries, const {Prayer.fajr: NoJamaat()});
    });

    test('equality compares id, name, and entry maps', () {
      const a = MosqueProfile(
        id: 'p1',
        name: 'Home',
        entries: {Prayer.dhuhr: FixedJamaat(ClockTime(13, 15))},
      );
      const b = MosqueProfile(
        id: 'p1',
        name: 'Home',
        entries: {Prayer.dhuhr: FixedJamaat(ClockTime(13, 15))},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      expect(a, isNot(b.copyWith(name: 'Work')));
      expect(a, isNot(b.copyWith(entries: const {Prayer.dhuhr: NoJamaat()})));
      expect(a, isNot(const MosqueProfile(id: 'p2', name: 'Home')));
      expect(a, isNot(b.copyWith(entries: const {})));
    });
  });

  group('MosqueState', () {
    final home = MosqueProfile.create(id: 'home', name: 'Home');
    final work = MosqueProfile.create(id: 'work', name: 'Work');

    test('active resolves the profile matching activeId', () {
      final state = MosqueState(profiles: [home, work], activeId: 'work');
      expect(state.active, work);
      expect(state.activeConfig.entries, work.config.entries);
    });

    test('stale activeId falls back to the first profile', () {
      final state = MosqueState(profiles: [home, work], activeId: 'gone');
      expect(state.active, home);
      expect(state.activeConfig.entries, home.config.entries);
    });

    test('stale activeId with no profiles → null', () {
      const state = MosqueState(activeId: 'gone');
      expect(state.active, isNull);
      expect(state.activeConfig, JamaatConfig.none);
    });

    test('active is null when activeId is null', () {
      final state = MosqueState(profiles: [home]);
      expect(state.active, isNull);
      expect(state.activeConfig, JamaatConfig.none);
    });

    test('copyWith preserves activeId; withActive clears it', () {
      final state = MosqueState(profiles: [home], activeId: 'home');
      expect(state.copyWith(profiles: [home, work]).activeId, 'home');
      expect(state.copyWith(activeId: 'work').activeId, 'work');
      expect(state.withActive(null).activeId, isNull);
      expect(state.withActive(null).profiles, [home]);
    });

    test('equality compares profiles element-wise', () {
      final a = MosqueState(profiles: [home, work], activeId: 'home');
      final b = MosqueState(
        profiles: [
          MosqueProfile.create(id: 'home', name: 'Home'),
          MosqueProfile.create(id: 'work', name: 'Work'),
        ],
        activeId: 'home',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      expect(a, isNot(MosqueState(profiles: [work, home], activeId: 'home')));
      expect(a, isNot(MosqueState(profiles: [home], activeId: 'home')));
      expect(a, isNot(MosqueState(profiles: [home, work])));
    });
  });
}
