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
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
          ),
          MosqueRule(
            mosqueId: 'b',
            start: ClockTime(0, 0),
            end: ClockTime(0, 0),
          ),
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
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(11, 0),
          ),
        ],
      );
      expect(resolveAutoMosqueId(state, now), 'b');
    });

    test('ignores rules pointing at missing profiles', () {
      const state = MosqueState(
        profiles: [_b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(
            mosqueId: 'gone',
            start: ClockTime(0, 0),
            end: ClockTime(0, 0),
          ),
        ],
      );
      expect(resolveAutoMosqueId(state, now), 'b');
    });
  });

  group('resolveActiveMosque', () {
    final now = DateTime(2026, 6, 15, 11);

    test('manual mode returns the active profile', () {
      const state = MosqueState(profiles: [_a, _b], activeId: 'b');
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
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
          ),
        ],
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _a);
      expect(r.isAuto, isTrue);
      expect(r.isOverride, isFalse);
    });

    test('a valid override (baseline matches auto) takes effect', () {
      final state = MosqueState(
        profiles: const [_a, _b],
        mode: ScheduleMode.auto,
        rules: const [
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
          ),
        ],
        activeOverride: MosqueOverride(
          mosqueId: 'b',
          baselineAutoId: 'a',
          setOn: DateTime(2026, 6, 15),
        ),
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _b);
      expect(r.isOverride, isTrue);
    });

    test('an override lapses at the end of its day, same window or not', () {
      // Every-day 10–18 rule: tomorrow at 11 resolves to 'a' again, so the
      // baseline still matches — only the day bound expires it.
      final state = MosqueState(
        profiles: const [_a, _b],
        mode: ScheduleMode.auto,
        rules: const [
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
          ),
        ],
        activeOverride: MosqueOverride(
          mosqueId: 'b',
          baselineAutoId: 'a',
          setOn: DateTime(2026, 6, 15),
        ),
      );
      final r = resolveActiveMosque(state, DateTime(2026, 6, 16, 11));
      expect(r.profile, _a);
      expect(r.isOverride, isFalse);
    });

    test('an override set in an overnight window outlives midnight', () {
      // Fri 2026-06-19 20:00–02:00 → 'a'; overridden to 'b' at 23:30.
      final state = MosqueState(
        profiles: const [_a, _b],
        mode: ScheduleMode.auto,
        rules: const [
          MosqueRule(
            mosqueId: 'a',
            days: {DateTime.friday},
            start: ClockTime(20, 0),
            end: ClockTime(2, 0),
          ),
        ],
        activeOverride: MosqueOverride(
          mosqueId: 'b',
          baselineAutoId: 'a',
          setOn: DateTime(2026, 6, 19),
        ),
      );
      expect(
        resolveActiveMosque(state, DateTime(2026, 6, 20, 0, 30)).profile,
        _b,
      );
      expect(
        state.activeOverride!.liveAt(DateTime(2026, 6, 20, 2, 30), state.rules),
        isFalse,
      );
    });

    test('a legacy override without a set day is treated as expired', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
          ),
        ],
        activeOverride: MosqueOverride(mosqueId: 'b', baselineAutoId: 'a'),
      );
      expect(resolveActiveMosque(state, now).isOverride, isFalse);
    });

    test('a stale override (boundary crossed) is ignored', () {
      const state = MosqueState(
        profiles: [_a, _b],
        mode: ScheduleMode.auto,
        rules: [
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(10, 0),
            end: ClockTime(18, 0),
          ),
        ],
        // Auto now resolves to 'a', but the override was baselined to 'b'.
        activeOverride: MosqueOverride(mosqueId: 'b', baselineAutoId: 'b'),
      );
      final r = resolveActiveMosque(state, now);
      expect(r.profile, _a);
      expect(r.isOverride, isFalse);
    });
  });

  const winter = MosqueSeason(
    mosqueId: 'b',
    start: (month: 11, day: 1),
    end: (month: 2, day: 28),
  );

  group('MosqueSeason.contains', () {
    test('plain range is inclusive at both ends', () {
      const summer = MosqueSeason(
        mosqueId: 'a',
        start: (month: 4, day: 1),
        end: (month: 9, day: 30),
      );
      expect(summer.contains(DateTime(2026, 4)), isTrue);
      expect(summer.contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(summer.contains(DateTime(2026, 3, 31)), isFalse);
      expect(summer.contains(DateTime(2026, 10)), isFalse);
    });

    test('range wrapping the year end matches both sides', () {
      expect(winter.contains(DateTime(2026, 11)), isTrue);
      expect(winter.contains(DateTime(2026, 12, 31)), isTrue);
      expect(winter.contains(DateTime(2027, 1, 15)), isTrue);
      expect(winter.contains(DateTime(2027, 2, 28)), isTrue);
      expect(winter.contains(DateTime(2027, 3)), isFalse);
      expect(winter.contains(DateTime(2026, 10, 31)), isFalse);
      expect(winter.contains(DateTime(2026, 6)), isFalse);
    });

    test('Feb 29 ends behave in leap and common years', () {
      const toLeapDay = MosqueSeason(
        mosqueId: 'b',
        start: (month: 11, day: 1),
        end: (month: 2, day: 29),
      );
      expect(toLeapDay.contains(DateTime(2028, 2, 29)), isTrue);
      expect(toLeapDay.contains(DateTime(2027, 2, 28)), isTrue);
      expect(toLeapDay.contains(DateTime(2027, 3)), isFalse);
      // A Feb 28 end leaves the leap day out.
      expect(winter.contains(DateTime(2028, 2, 29)), isFalse);
      const fromLeapDay = MosqueSeason(
        mosqueId: 'b',
        start: (month: 2, day: 29),
        end: (month: 3, day: 31),
      );
      expect(fromLeapDay.contains(DateTime(2027, 2, 28)), isFalse);
      expect(fromLeapDay.contains(DateTime(2027, 3)), isTrue);
      expect(fromLeapDay.contains(DateTime(2028, 2, 29)), isTrue);
    });

    test('equal ends cover just that day', () {
      const oneDay = MosqueSeason(
        mosqueId: 'a',
        start: (month: 7, day: 4),
        end: (month: 7, day: 4),
      );
      expect(oneDay.contains(DateTime(2026, 7, 4)), isTrue);
      expect(oneDay.contains(DateTime(2026, 7, 5)), isFalse);
    });

    test('documented Feb 29 gaps', () {
      const leapDayOnly = MosqueSeason(
        mosqueId: 'a',
        start: (month: 2, day: 29),
        end: (month: 2, day: 29),
      );
      expect(leapDayOnly.contains(DateTime(2028, 2, 29)), isTrue);
      for (final d in [DateTime(2027, 2, 28), DateTime(2027, 3)]) {
        expect(leapDayOnly.contains(d), isFalse); // never in a common year
      }
      const marToFeb28 = MosqueSeason(
        mosqueId: 'a',
        start: (month: 3, day: 1),
        end: (month: 2, day: 28),
      );
      expect(marToFeb28.contains(DateTime(2028, 2, 28)), isTrue);
      expect(marToFeb28.contains(DateTime(2028, 2, 29)), isFalse);
    });
  });

  group('seasons in resolution', () {
    const base = MosqueState(
      profiles: [_a, _b],
      mode: ScheduleMode.auto,
      defaultId: 'a',
      seasons: [winter],
    );

    test('inside the season it replaces the default', () {
      final r = resolveActiveMosque(base, DateTime(2026, 12, 10, 9));
      expect(r.profile, _b);
      expect(r.reason, MosqueReason.season);
      expect(r.season, winter);
    });

    test('outside the season the default applies', () {
      final r = resolveActiveMosque(base, DateTime(2026, 7, 10, 9));
      expect(r.profile, _a);
      expect(r.reason, MosqueReason.defaultMosque);
      expect(r.season, isNull);
    });

    test('without a default, the fallback is labelled as such', () {
      final r = resolveActiveMosque(
        base.withDefault(null),
        DateTime(2026, 7, 10, 9),
      );
      expect(r.profile, _a);
      expect(r.reason, MosqueReason.fallback);
    });

    test('a matching time rule beats the season', () {
      final state = base.copyWith(
        rules: const [
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(12, 0),
            end: ClockTime(14, 0),
          ),
        ],
      );
      final noon = resolveActiveMosque(state, DateTime(2026, 12, 10, 13));
      expect(noon.profile, _a);
      expect(noon.reason, MosqueReason.rule);
      final evening = resolveActiveMosque(state, DateTime(2026, 12, 10, 19));
      expect(evening.profile, _b);
      expect(evening.reason, MosqueReason.season);
    });

    test('first matching season wins; dangling ones are skipped', () {
      final state = base.copyWith(
        seasons: const [
          MosqueSeason(
            mosqueId: 'gone',
            start: (month: 1, day: 1),
            end: (month: 12, day: 31),
          ),
          winter,
          MosqueSeason(
            mosqueId: 'a',
            start: (month: 12, day: 1),
            end: (month: 12, day: 31),
          ),
        ],
      );
      expect(resolveAutoMosqueId(state, DateTime(2026, 12, 10)), 'b');
    });

    test('manual mode ignores seasons', () {
      final state = base.copyWith(mode: ScheduleMode.manual, activeId: 'a');
      final r = resolveActiveMosque(state, DateTime(2026, 12, 10));
      expect(r.profile, _a);
      expect(r.reason, MosqueReason.manual);
    });

    test('a season boundary expires an override like a rule boundary', () {
      final state = base.withOverride(
        MosqueOverride(
          mosqueId: 'b',
          baselineAutoId: 'a',
          setOn: DateTime(2026, 10, 31),
        ),
      );
      expect(
        resolveActiveMosque(state, DateTime(2026, 10, 31, 20)).reason,
        MosqueReason.override,
      );
      // Same-day check isolated: an override baselined to the pre-season
      // default no longer matches once the season resolves to 'b'.
      final stale = base.withOverride(
        MosqueOverride(
          mosqueId: 'a',
          baselineAutoId: 'a',
          setOn: DateTime(2026, 11),
        ),
      );
      final r = resolveActiveMosque(stale, DateTime(2026, 11, 1, 9));
      expect(r.isOverride, isFalse);
      expect(r.profile, _b);
    });
  });
}
