import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/calculators/domain/usecases/fitra_calculator.dart';

void main() {
  group('FitraCalculator.weightKgPerPerson', () {
    test('documented per-staple weights', () {
      expect(FitraCalculator.weightKgPerPerson[FitraStaple.wheat], 1.65);
      expect(FitraCalculator.weightKgPerPerson[FitraStaple.flour], 1.65);
      expect(FitraCalculator.weightKgPerPerson[FitraStaple.barley], 3.30);
      expect(FitraCalculator.weightKgPerPerson[FitraStaple.dates], 3.30);
      expect(FitraCalculator.weightKgPerPerson[FitraStaple.raisins], 3.30);
    });

    test('every staple has a weight', () {
      for (final staple in FitraStaple.values) {
        expect(staple.kgPerPerson, greaterThan(0));
      }
    });

    test('kgPerPerson extension mirrors the map', () {
      for (final staple in FitraStaple.values) {
        expect(staple.kgPerPerson, FitraCalculator.weightKgPerPerson[staple]);
      }
    });
  });

  group('FitraCalculator.calculate — per-staple math (price 50, 1 person)', () {
    const price = 50.0;

    void expectStaple(FitraStaple staple, double kg) {
      final r = FitraCalculator.calculate(
        FitraInput(staple: staple, pricePerKg: price),
      );
      expect(r.weightKgPerPerson, kg);
      expect(r.perPersonAmount, closeTo(kg * price, 0.001));
      expect(r.totalAmount, closeTo(kg * price, 0.001));
      expect(r.totalWeightKg, closeTo(kg, 0.001));
    }

    test('wheat → half sa', () => expectStaple(FitraStaple.wheat, 1.65));
    test('flour → half sa', () => expectStaple(FitraStaple.flour, 1.65));
    test('barley → full sa', () => expectStaple(FitraStaple.barley, 3.30));
    test('dates → full sa', () => expectStaple(FitraStaple.dates, 3.30));
    test('raisins → full sa', () => expectStaple(FitraStaple.raisins, 3.30));
  });

  group('FitraCalculator.calculate — people scaling', () {
    test('total scales linearly with the number of people', () {
      final r = FitraCalculator.calculate(
        const FitraInput(
          staple: FitraStaple.wheat,
          pricePerKg: 100,
          numberOfPeople: 4,
        ),
      );
      expect(r.perPersonAmount, closeTo(165, 0.001)); // 1.65 * 100
      expect(r.totalAmount, closeTo(660, 0.001)); // 165 * 4
      expect(r.weightKgPerPerson, 1.65);
      expect(r.totalWeightKg, closeTo(6.6, 0.001)); // 1.65 * 4
    });

    test('barley household of 5', () {
      final r = FitraCalculator.calculate(
        const FitraInput(
          staple: FitraStaple.barley,
          pricePerKg: 60,
          numberOfPeople: 5,
        ),
      );
      expect(r.perPersonAmount, closeTo(198, 0.001)); // 3.30 * 60
      expect(r.totalAmount, closeTo(990, 0.001)); // 198 * 5
      expect(r.totalWeightKg, closeTo(16.5, 0.001)); // 3.30 * 5
    });

    test('default number of people is 1', () {
      final r = FitraCalculator.calculate(
        const FitraInput(staple: FitraStaple.dates, pricePerKg: 200),
      );
      expect(r.totalAmount, closeTo(r.perPersonAmount, 0.001));
      expect(r.totalWeightKg, closeTo(r.weightKgPerPerson, 0.001));
    });

    test('zero people → zero totals but weight still reported', () {
      final r = FitraCalculator.calculate(
        const FitraInput(
          staple: FitraStaple.wheat,
          pricePerKg: 100,
          numberOfPeople: 0,
        ),
      );
      expect(r.perPersonAmount, closeTo(165, 0.001));
      expect(r.totalAmount, 0);
      expect(r.totalWeightKg, 0);
      expect(r.weightKgPerPerson, 1.65);
    });
  });

  group('FitraCalculator.calculate — defensive clamping', () {
    test('zero price → zero amounts, weight preserved', () {
      final r = FitraCalculator.calculate(
        const FitraInput(staple: FitraStaple.dates, pricePerKg: 0),
      );
      expect(r.perPersonAmount, 0);
      expect(r.totalAmount, 0);
      expect(r.weightKgPerPerson, 3.30);
      expect(r.totalWeightKg, closeTo(3.30, 0.001));
    });

    test('negative price is clamped to 0', () {
      final r = FitraCalculator.calculate(
        const FitraInput(
          staple: FitraStaple.wheat,
          pricePerKg: -100,
          numberOfPeople: 3,
        ),
      );
      expect(r.perPersonAmount, 0);
      expect(r.totalAmount, 0);
      expect(r.totalWeightKg, closeTo(4.95, 0.001)); // 1.65 * 3
    });

    test('negative people clamped to 0', () {
      final r = FitraCalculator.calculate(
        const FitraInput(
          staple: FitraStaple.raisins,
          pricePerKg: 80,
          numberOfPeople: -5,
        ),
      );
      expect(r.totalAmount, 0);
      expect(r.totalWeightKg, 0);
      expect(r.perPersonAmount, closeTo(264, 0.001)); // 3.30 * 80
    });

    test('negative price and negative people both clamped', () {
      final r = FitraCalculator.calculate(
        const FitraInput(
          staple: FitraStaple.barley,
          pricePerKg: -50,
          numberOfPeople: -2,
        ),
      );
      expect(r.perPersonAmount, 0);
      expect(r.totalAmount, 0);
      expect(r.totalWeightKg, 0);
    });
  });

  group('FitraCalculator.calculate — result invariants', () {
    test('totalAmount equals perPersonAmount times people', () {
      for (final staple in FitraStaple.values) {
        for (final people in [0, 1, 2, 7]) {
          final r = FitraCalculator.calculate(
            FitraInput(
              staple: staple,
              pricePerKg: 33.5,
              numberOfPeople: people,
            ),
          );
          expect(
            r.totalAmount,
            closeTo(r.perPersonAmount * people, 0.001),
            reason: '$staple x $people',
          );
          expect(
            r.totalWeightKg,
            closeTo(r.weightKgPerPerson * people, 0.001),
            reason: '$staple x $people',
          );
        }
      }
    });
  });
}
