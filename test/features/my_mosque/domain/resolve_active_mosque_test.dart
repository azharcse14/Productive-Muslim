import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/resolve_active_mosque.dart';

const _a = MosqueProfile(id: 'a', name: 'Office');
const _b = MosqueProfile(id: 'b', name: 'Home');

void main() {
  group('MosqueRule.matches', () {
    final at1030 = DateTime(2026, 6, 15, 10, 30);

    test('all-day rule (start == end) always matches', () {
      const rule = MosqueRule(
        mosqueId: 'a',
        start: ClockTime(0, 0),
        end: ClockTime(0, 0),
      );
      expect(rule.matches(at1030), isTrue);
    });

    test('normal window is inclusive of start, exclusive of end', () {
      const rule = MosqueRule(
        mosqueId: 'a',
        start: ClockTime(10, 0),
        end: ClockTime(18, 0),
      );
      expect(rule.matches(DateTime(2026, 6, 15, 10)), isTrue);
      expect(rule.matches(DateTime(2026, 6, 15, 17, 59)), isTrue);
      expect(rule.matches(DateTime(2026, 6, 15, 18)), isFalse);
      expect(rule.matches(DateTime(2026, 6, 15, 9, 59)), isFalse);
    });

    test('window wrapping past midnight matches both sides', () {
      const rule = MosqueRule(
        mosqueId: 'a',
        start: ClockTime(22, 0),
        end: ClockTime(2, 0),
      );
      expect(rule.matches(DateTime(2026, 6, 15, 23)), isTrue);
      expect(rule.matches(DateTime(2026, 6, 15, 1)), isTrue);
      expect(rule.matches(DateTime(2026, 6, 15, 12)), isFalse);
    });

    test('overnight weekday rule keeps matching after midnight', () {
      // 2026-06-19 is a Friday.
      const friday = MosqueRule(
        mosqueId: 'a',
        days: {DateTime.friday},
        start: ClockTime(20, 0),
        end: ClockTime(2, 0),
      );
      expect(friday.matches(DateTime(2026, 6, 19, 21)), isTrue);
      expect(friday.matches(DateTime(2026, 6, 20, 0, 30)), isTrue);
      expect(friday.matches(DateTime(2026, 6, 20, 21)), isFalse);
      expect(friday.matches(DateTime(2026, 6, 19, 0, 30)), isFalse);
    });

    test('weekday filter restricts the matching days', () {
      final today = at1030.weekday;
      final otherDay = today % 7 + 1;
      final onlyToday = MosqueRule(
        mosqueId: 'a',
        start: const ClockTime(0, 0),
        end: const ClockTime(0, 0),
        days: {today},
      );
      final onlyOther = MosqueRule(
        mosqueId: 'a',
        start: const ClockTime(0, 0),
        end: const ClockTime(0, 0),
        days: {otherDay},
      );
      expect(onlyToday.matches(at1030), isTrue);
      expect(onlyOther.matches(at1030), isFalse);
    });
  });

  group('resolveAutoMosqueId', () {
    final now = DateTime(2026, 6, 15, 11);

    test('first matching rule wins', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(mosqueId: 'a', start: ClockTime(10, 0), end: ClockTime(18, 0)),
          MosqueRule(mosqueId: 'b', start: ClockTime(0, 0), end: ClockTime(0, 0)),
        ],
      );
      expect(resolveAutoMosqueId(state, now), 'a');
    });

    test('falls back to the default when no rule matches', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        defaultId: 'b',
        rules: [
          MosqueRule(mosqueId: 'a', start: ClockTime(10, 0), end: ClockTime(11, 0)),
        ],
      );
      expect(resolveAutoMosqueId(state, now), 'b');
    });

    test('ignores rules pointing at missing profiles', () {
      const state = MosqueState(
        profiles: [_b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(mosqueId: 'gone', start: ClockTime(0, 0), end: ClockTime(0, 0)),
        ],
      );
      expect(resolveAutoMosqueId(state, now), 'b');
    });
  });

  group('resolveActiveMosque', () {
    final now = DateTime(2026, 6, 15, 11);

    test('manual mode returns the active profile', () {
      const state = MosqueState(
        profiles: [_a, _b],
        activeId: 'b',
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _b);
      expect(r.isAuto, isFalse);
      expect(r.isOverride, isFalse);
    });

    test('auto mode returns the scheduled mosque', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        defaultId: 'b',
        rules: [
          MosqueRule(mosqueId: 'a', start: ClockTime(10, 0), end: ClockTime(18, 0)),
        ],
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _a);
      expect(r.isAuto, isTrue);
      expect(r.isOverride, isFalse);
    });

    test('a valid override (baseline matches auto) takes effect', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(mosqueId: 'a', start: ClockTime(10, 0), end: ClockTime(18, 0)),
        ],
        activeOverride: MosqueOverride(mosqueId: 'b', baselineAutoId: 'a'),
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _b);
      expect(r.isOverride, isTrue);
    });

    test('a stale override (boundary crossed) is ignored', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(mosqueId: 'a', start: ClockTime(10, 0), end: ClockTime(18, 0)),
        ],
        // Auto now resolves to 'a', but the override was baselined to 'b'.
        activeOverride: MosqueOverride(mosqueId: 'b', baselineAutoId: 'b'),
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _a);
      expect(r.isOverride, isFalse);
    });
  });
}
