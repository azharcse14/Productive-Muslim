// Explicit DateTime(year, 1, 1) literals read more clearly in date-math
// assertions than the bare DateTime(year) shorthand.
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/calculators/domain/usecases/qaza_calculator.dart';

void main() {
  group('QazaCalculator.calculate', () {
    test('same day start and end → 1 inclusive day', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 14),
          endDate: DateTime(2026, 6, 14),
        ),
      );
      expect(r.days, 1);
      expect(r.perPrayer, 1);
      expect(r.witr, 0);
      expect(r.totalMissed, 5);
    });

    test('inclusive week range is 7 days', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 7),
        ),
      );
      expect(r.days, 7);
      expect(r.perPrayer, 7);
      expect(r.totalMissed, 35);
    });

    test('time component is ignored (date-only convention)', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 14, 23, 59),
          endDate: DateTime(2026, 6, 15, 0, 1),
        ),
      );
      expect(r.days, 2);
      expect(r.perPrayer, 2);
    });

    test('leap-year span: full Feb 2024 (29 days) is 29', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2024, 2, 1),
          endDate: DateTime(2024, 2, 29),
        ),
      );
      expect(r.days, 29);
      expect(r.perPrayer, 29);
      expect(r.totalMissed, 145);
    });

    test('non-leap-year Feb 2023 is 28 days', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2023, 2, 1),
          endDate: DateTime(2023, 2, 28),
        ),
      );
      expect(r.days, 28);
    });

    test('multi-year span across a leap day counts correctly', () {
      // 2023-06-14 .. 2024-06-14 inclusive: 366 days + 1 (2024 is leap and
      // Feb 29 lies within the window) = 367.
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2023, 6, 14),
          endDate: DateTime(2024, 6, 14),
        ),
      );
      expect(r.days, 367);
      expect(r.perPrayer, 367);
      expect(r.totalMissed, 367 * 5);
    });

    test('endDate before startDate → everything zero, empty breakdown', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 14),
          endDate: DateTime(2026, 6, 13),
        ),
      );
      expect(r.days, 0);
      expect(r.perPrayer, 0);
      expect(r.witr, 0);
      expect(r.totalMissed, 0);
      expect(r.breakdown, isEmpty);
    });

    test('includeWitr adds a sixth daily prayer', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10),
          includeWitr: true,
        ),
      );
      expect(r.days, 10);
      expect(r.perPrayer, 10);
      expect(r.witr, 10);
      // 5 daily prayers + witr = 6 × 10.
      expect(r.totalMissed, 60);
    });

    test('witr is 0 when not included', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10),
        ),
      );
      expect(r.witr, 0);
      expect(r.totalMissed, 50);
    });

    test('alreadyMadeUp subtracted from each prayer', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10), // 10 days
          alreadyMadeUpPerPrayer: 3,
        ),
      );
      expect(r.perPrayer, 7);
      expect(r.totalMissed, 35);
    });

    test('alreadyMadeUp also reduces witr when included', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 10), // 10 days
          includeWitr: true,
          alreadyMadeUpPerPrayer: 4,
        ),
      );
      expect(r.perPrayer, 6);
      expect(r.witr, 6);
      expect(r.totalMissed, 36);
    });

    test('alreadyMadeUp exceeding days clamps perPrayer to 0', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 5), // 5 days
          alreadyMadeUpPerPrayer: 100,
        ),
      );
      expect(r.perPrayer, 0);
      expect(r.witr, 0);
      expect(r.totalMissed, 0);
    });

    test('negative alreadyMadeUp is clamped to 0 (no inflation)', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 5), // 5 days
          alreadyMadeUpPerPrayer: -10,
        ),
      );
      expect(r.perPrayer, 5);
      expect(r.totalMissed, 25);
    });

    test('breakdown maps the five daily prayers when witr excluded', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 3), // 3 days
        ),
      );
      expect(r.breakdown.keys, containsAll(QazaCalculator.dailyPrayers));
      expect(r.breakdown.containsKey('witr'), isFalse);
      expect(r.breakdown['fajr'], 3);
      expect(r.breakdown['isha'], 3);
      expect(r.breakdown.length, 5);
    });

    test('breakdown includes witr key when included', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 3), // 3 days
          includeWitr: true,
        ),
      );
      expect(r.breakdown.length, 6);
      expect(r.breakdown['witr'], 3);
    });

    test('breakdown daily values sum + witr equals totalMissed', () {
      final r = QazaCalculator.calculate(
        QazaInput(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31), // 31 days
          includeWitr: true,
          alreadyMadeUpPerPrayer: 5,
        ),
      );
      final sum = r.breakdown.values.fold(0, (a, b) => a + b);
      expect(sum, r.totalMissed);
      expect(r.perPrayer, 26);
      expect(r.totalMissed, 26 * 6);
    });

    test('dailyPrayers constant lists the five obligatory prayers', () {
      expect(
        QazaCalculator.dailyPrayers,
        ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'],
      );
    });
  });
}
