import 'dart:math' as math;

/// Everything the user owns (and owes) for a Zakat calculation, all in the
/// user's own currency. Metal holdings are entered in grams and valued via
/// the per-gram prices.
///
/// Negative values are tolerated defensively: [ZakatCalculator.calculate]
/// clamps every field to ≥ 0 so bad input can never reduce another total.
final class ZakatInput {
  const ZakatInput({
    this.cashOnHand = 0,
    this.bankBalance = 0,
    this.goldGrams = 0,
    this.silverGrams = 0,
    this.businessAssets = 0,
    this.investments = 0,
    this.moneyOwedToYou = 0,
    this.debts = 0,
    required this.goldPricePerGram,
    required this.silverPricePerGram,
  });

  final double cashOnHand;
  final double bankBalance;
  final double goldGrams;
  final double silverGrams;
  final double businessAssets;
  final double investments;

  /// Receivables the user realistically expects back (zakatable).
  final double moneyOwedToYou;

  /// Immediate liabilities, deducted before comparing against nisab.
  final double debts;

  final double goldPricePerGram;
  final double silverPricePerGram;
}

/// Outcome of [ZakatCalculator.calculate] — totals, the nisab threshold
/// used, and a per-category breakdown for the UI.
final class ZakatResult {
  const ZakatResult({
    required this.totalWealth,
    required this.zakatableWealth,
    required this.nisabThreshold,
    required this.isPayable,
    required this.zakatDue,
    required this.cashTotal,
    required this.metalsValue,
    required this.businessTotal,
  });

  /// Sum of all assets before deducting debts.
  final double totalWealth;

  /// [totalWealth] minus debts, floored at 0.
  final double zakatableWealth;

  /// The lower of the gold-based and silver-based nisab values — the safer
  /// threshold (standard position: it benefits the poor since Zakat becomes
  /// due sooner). A metal with no price (0) is ignored; 0 only when neither
  /// price is provided.
  final double nisabThreshold;

  /// Whether Zakat is due: wealth meets nisab and the threshold is real
  /// (a zero threshold means no metal prices were provided).
  final bool isPayable;

  /// 2.5% of [zakatableWealth] when payable, otherwise 0.
  final double zakatDue;

  /// Cash on hand + bank balance.
  final double cashTotal;

  /// Gold + silver holdings at the given per-gram prices.
  final double metalsValue;

  /// Business assets + investments + money owed to you.
  final double businessTotal;
}

/// Pure Zakat math (guide §6: domain logic is static, side-effect free,
/// exhaustively tested). No rounding is applied — presentation formats.
abstract final class ZakatCalculator {
  /// Classical gold nisab: 20 mithqal ≈ 87.48 g.
  static const double nisabGoldGrams = 87.48;

  /// Classical silver nisab: 200 dirham ≈ 612.36 g.
  static const double nisabSilverGrams = 612.36;

  /// Zakat rate: 2.5% (one fortieth).
  static const double rate = 0.025;

  /// Computes the full Zakat result for [input].
  ///
  /// Every field is clamped to ≥ 0 (non-finite → 0) first, so a negative entry can never
  /// drag a total below zero. A missing (0) metal price is ignored for
  /// nisab; a nisab of 0 (both prices missing) makes the result non-payable
  /// rather than trivially payable.
  static ZakatResult calculate(ZakatInput input) {
    final goldPrice = _clamp(input.goldPricePerGram);
    final silverPrice = _clamp(input.silverPricePerGram);

    final cashTotal = _clamp(input.cashOnHand) + _clamp(input.bankBalance);
    final metalsValue = _clamp(input.goldGrams) * goldPrice +
        _clamp(input.silverGrams) * silverPrice;
    final businessTotal = _clamp(input.businessAssets) +
        _clamp(input.investments) +
        _clamp(input.moneyOwedToYou);

    final totalWealth = cashTotal + metalsValue + businessTotal;
    final zakatableWealth = math.max(0.0, totalWealth - _clamp(input.debts));

    // The lower (silver, usually) threshold is the standard safer choice:
    // Zakat becomes due on less wealth, which benefits the poor. Only prices
    // actually provided (> 0) count — a blank price is unknown, not free.
    final candidates = [
      if (goldPrice > 0) nisabGoldGrams * goldPrice,
      if (silverPrice > 0) nisabSilverGrams * silverPrice,
    ];
    final nisabThreshold =
        candidates.isEmpty ? 0.0 : candidates.reduce(math.min);

    final isPayable = nisabThreshold > 0 && zakatableWealth >= nisabThreshold;

    return ZakatResult(
      totalWealth: totalWealth,
      zakatableWealth: zakatableWealth,
      nisabThreshold: nisabThreshold,
      isPayable: isPayable,
      zakatDue: isPayable ? zakatableWealth * rate : 0,
      cashTotal: cashTotal,
      metalsValue: metalsValue,
      businessTotal: businessTotal,
    );
  }

  /// Negative and non-finite (NaN/Infinity) values count as 0.
  static double _clamp(double value) => value.isFinite && value > 0 ? value : 0;
}
