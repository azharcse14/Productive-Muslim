import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/my_mosque/data/models/mosque_state_model.dart';
import 'package:qalbee/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:qalbee/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:qalbee/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:qalbee/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:qalbee/features/settings/domain/entities/prayer_params.dart';

void main() {
  group('MosqueStateModel', () {
    test('round-trips multiple profiles with all entry types', () {
      const state = MosqueState(
        profiles: [
          MosqueProfile(
            id: 'home',
            name: 'Home Mosque',
            entries: {
              Prayer.fajr: FixedJamaat(ClockTime(5, 45)),
              Prayer.maghrib: OffsetJamaat(Duration(minutes: 5)),
              Prayer.isha: NoJamaat(),
            },
          ),
          MosqueProfile(
            id: 'work',
            name: 'Work Mosque',
            entries: {Prayer.dhuhr: FixedJamaat(ClockTime(13, 30))},
          ),
        ],
        activeId: 'work',
      );
      expect(MosqueStateModel.fromMap(MosqueStateModel.toMap(state)), state);
    });

    test('round-trips the auto schedule (mode, rules, default, override)', () {
      const state = MosqueState(
        profiles: [
          MosqueProfile(id: 'office', name: 'Office'),
          MosqueProfile(id: 'home', name: 'Home'),
        ],
        activeId: 'home',
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(
            mosqueId: 'office',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
            days: {1, 2, 3, 4, 5},
          ),
          MosqueRule(
            mosqueId: 'home',
            start: ClockTime(0, 0),
            end: ClockTime(0, 0),
            days: {6, 7},
          ),
        ],
        defaultId: 'home',
        activeOverride: MosqueOverride(mosqueId: 'office', baselineAutoId: 'home'),
      );
      expect(MosqueStateModel.fromMap(MosqueStateModel.toMap(state)), state);
    });

    test('empty map yields defaults (manual, no rules)', () {
      final restored = MosqueStateModel.fromMap(const {});
      expect(restored, const MosqueState());
      expect(restored.mode, ScheduleMode.manual);
      expect(restored.rules, isEmpty);
    });

    test('corrupt rules are skipped without throwing', () {
      final state = MosqueStateModel.fromMap(const {
        'mode': 'auto',
        'rules': [
          'garbage',
          {'mosqueId': 'a'}, // missing times
          {
            'mosqueId': 'a',
            'start': {'hour': 10, 'minute': 0},
            'end': {'hour': 18, 'minute': 0},
            'days': [1, 99, 'x'],
          },
        ],
      });
      expect(state.mode, ScheduleMode.auto);
      expect(state.rules.single.mosqueId, 'a');
      expect(state.rules.single.days, {1});
    });

    test('null activeId round-trips', () {
      const state = MosqueState(
        profiles: [MosqueProfile(id: 'home', name: 'Home')],
      );
      final restored = MosqueStateModel.fromMap(MosqueStateModel.toMap(state));
      expect(restored.activeId, isNull);
      expect(restored, state);
    });

    test('unknown entry type is skipped (treated as unset)', () {
      final state = MosqueStateModel.fromMap(const {
        'profiles': [
          {
            'id': 'home',
            'name': 'Home',
            'entries': {
              'fajr': {'type': 'sunset_relative', 'minutes': 10},
              'isha': {'type': 'none'},
            },
          },
        ],
        'activeId': 'home',
      });
      expect(state.profiles.single.entries, const {Prayer.isha: NoJamaat()});
    });

    test('corrupt entry shapes are skipped without throwing', () {
      final state = MosqueStateModel.fromMap(const {
        'profiles': [
          {
            'id': 'home',
            'name': 'Home',
            'entries': {
              'fajr': {'type': 'fixed', 'hour': 'five'},
              'dhuhr': {'type': 'fixed', 'hour': 99, 'minute': 0},
              'asr': {'type': 'offset'},
              'maghrib': 42,
              'isha': {'type': 'offset', 'minutes': 10},
            },
          },
        ],
      });
      expect(state.profiles.single.entries, const {
        Prayer.isha: OffsetJamaat(Duration(minutes: 10)),
      });
    });

    test('corrupt profiles are skipped without throwing', () {
      final state = MosqueStateModel.fromMap(const {
        'profiles': [
          'garbage',
          {'name': 'No id'},
          {'id': 42, 'name': 'Bad id'},
          {'id': 'ok', 'name': 'Kept'},
        ],
        'activeId': 'ok',
      });
      expect(state.profiles, const [MosqueProfile(id: 'ok', name: 'Kept')]);
      expect(state.activeId, 'ok');
    });

    test('non-list profiles falls back to empty', () {
      final state = MosqueStateModel.fromMap(const {'profiles': 'oops'});
      expect(state, const MosqueState());
    });
  });
}
