import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/ramadan/domain/usecases/zakat_calculator.dart';

void main() {
  // Realistic-ish prices in an arbitrary currency.
  const goldPrice = 100.0; // gold nisab  = 87.48  * 100 = 8748
  const silverPrice = 1.0; // silver nisab = 612.36 *   1 = 612.36

  group('ZakatCalculator.calculate', () {
    test('below nisab → not payable, zero due', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 500,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.nisabThreshold, closeTo(612.36, 0.001));
      expect(r.isPayable, isFalse);
      expect(r.zakatDue, 0);
      expect(r.zakatableWealth, 500);
    });

    test('exactly at nisab → payable (>= comparison)', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 612.36,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.isPayable, isTrue);
      expect(r.zakatDue, closeTo(612.36 * 0.025, 0.01));
    });

    test('above nisab → 2.5% of zakatable wealth', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 10000,
          bankBalance: 30000,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.isPayable, isTrue);
      expect(r.zakatableWealth, 40000);
      expect(r.zakatDue, closeTo(1000, 0.01));
    });

    test('debts deducted before nisab comparison can void payability', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 1000,
          debts: 600,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.totalWealth, 1000);
      expect(r.zakatableWealth, 400);
      expect(r.isPayable, isFalse);
      expect(r.zakatDue, 0);
    });

    test('debts exceeding wealth floor zakatable wealth at 0', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 1000,
          debts: 5000,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.zakatableWealth, 0);
      expect(r.isPayable, isFalse);
      expect(r.zakatDue, 0);
    });

    test('nisab uses the lower threshold — silver when silver is cheaper',
        () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 5000,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      // Silver: 612.36 × 1 = 612.36 < gold: 87.48 × 100 = 8748.
      expect(r.nisabThreshold, closeTo(612.36, 0.001));
      // 5000 is below the gold nisab but above silver — payable.
      expect(r.isPayable, isTrue);
    });

    test('nisab uses the lower threshold — gold when gold is cheaper', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 5000,
          goldPricePerGram: 10,
          silverPricePerGram: 50,
        ),
      );
      // Gold: 87.48 × 10 = 874.8 < silver: 612.36 × 50 = 30618.
      expect(r.nisabThreshold, closeTo(874.8, 0.001));
      expect(r.isPayable, isTrue);
    });

    test('both prices zero → nisab 0 → never payable', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 1000000,
          goldPricePerGram: 0,
          silverPricePerGram: 0,
        ),
      );
      expect(r.nisabThreshold, 0);
      expect(r.isPayable, isFalse);
      expect(r.zakatDue, 0);
    });

    test('one price blank → nisab from the provided metal only', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 1000000,
          goldPricePerGram: goldPrice,
          silverPricePerGram: 0,
        ),
      );
      expect(
        r.nisabThreshold,
        closeTo(ZakatCalculator.nisabGoldGrams * goldPrice, 0.001),
      );
      expect(r.isPayable, isTrue);
    });

    test('breakdown fields sum to total wealth', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 1200,
          bankBalance: 3800,
          goldGrams: 10,
          silverGrams: 100,
          businessAssets: 7000,
          investments: 2500,
          moneyOwedToYou: 500,
          debts: 900,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.cashTotal, 5000);
      expect(r.metalsValue, closeTo(10 * goldPrice + 100 * silverPrice, 0.001));
      expect(r.businessTotal, 10000);
      expect(
        r.totalWealth,
        closeTo(r.cashTotal + r.metalsValue + r.businessTotal, 0.001),
      );
      expect(r.zakatableWealth, closeTo(r.totalWealth - 900, 0.001));
      expect(r.zakatDue, closeTo(r.zakatableWealth * 0.025, 0.01));
    });

    test('negative fields are clamped to 0, never reducing other totals', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: -500,
          bankBalance: 2000,
          goldGrams: -3,
          silverGrams: -1,
          businessAssets: -100,
          investments: -100,
          moneyOwedToYou: -100,
          debts: -999,
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.cashTotal, 2000);
      expect(r.metalsValue, 0);
      expect(r.businessTotal, 0);
      expect(r.totalWealth, 2000);
      // Negative debts must not inflate zakatable wealth.
      expect(r.zakatableWealth, 2000);
      expect(r.isPayable, isTrue);
      expect(r.zakatDue, closeTo(50, 0.01));
    });

    test('negative metal prices are clamped (nisab 0 → not payable)', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: 100000,
          goldGrams: 50,
          goldPricePerGram: -100,
          silverPricePerGram: -1,
        ),
      );
      expect(r.metalsValue, 0);
      expect(r.nisabThreshold, 0);
      expect(r.isPayable, isFalse);
    });

    test('all-default input with prices only → empty, not payable', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          goldPricePerGram: goldPrice,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.totalWealth, 0);
      expect(r.zakatableWealth, 0);
      expect(r.isPayable, isFalse);
      expect(r.zakatDue, 0);
    });

    test('non-finite input (NaN/Infinity) counts as zero', () {
      final r = ZakatCalculator.calculate(
        const ZakatInput(
          cashOnHand: double.nan,
          bankBalance: double.infinity,
          debts: double.nan,
          goldPricePerGram: double.infinity,
          silverPricePerGram: silverPrice,
        ),
      );
      expect(r.totalWealth, 0);
      expect(r.zakatableWealth, 0);
      expect(r.nisabThreshold, ZakatCalculator.nisabSilverGrams * silverPrice);
      expect(r.isPayable, isFalse);
      expect(r.zakatDue, 0);
    });

    test('classical constants', () {
      expect(ZakatCalculator.nisabGoldGrams, 87.48);
      expect(ZakatCalculator.nisabSilverGrams, 612.36);
      expect(ZakatCalculator.rate, 0.025);
    });
  });
}
