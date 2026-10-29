/// Staple foods accepted for Sadaqatul Fitr (Fitra), each with a commonly
/// cited contemporary per-person weight in kilograms.
///
/// Fitra is classically one *sa'* of a staple food per person. A sa' is
/// roughly 3.30 kg of grain (estimates vary by staple and density). The
/// widespread Hanafi position allows *half a sa'* (≈ 1.65 kg) when paying in
/// wheat or wheat flour, which is reflected here. These weights are
/// approximate, contemporary commonly-cited values — exposing the weight
/// lets users sidestep fiqh disputes by entering their own local price.
enum FitraStaple { wheat, barley, dates, raisins, flour }

/// Per-person weight (kg) for each [FitraStaple].
extension FitraStapleWeight on FitraStaple {
  /// Approximate per-person weight in kilograms.
  ///
  /// Wheat and flour use half a sa' (≈ 1.65 kg) per the common Hanafi
  /// position; barley, dates and raisins use a full sa' (≈ 3.30 kg).
  double get kgPerPerson => FitraCalculator.weightKgPerPerson[this]!;
}

/// Inputs for a single Fitra calculation, all in the user's own currency.
///
/// Negative values are tolerated defensively: [FitraCalculator.calculate]
/// clamps price and people to ≥ 0 so bad input can never produce a negative
/// total.
final class FitraInput {
  const FitraInput({
    required this.staple,
    required this.pricePerKg,
    this.numberOfPeople = 1,
  });

  /// The staple food whose per-person weight drives the calculation.
  final FitraStaple staple;

  /// Local market price of the chosen staple, per kilogram.
  final double pricePerKg;

  /// Household members the Fitra is paid for (one sa' each).
  final int numberOfPeople;
}

/// Outcome of [FitraCalculator.calculate] — the monetary amounts and the
/// weights they were derived from, so the UI can show the basis.
final class FitraResult {
  const FitraResult({
    required this.perPersonAmount,
    required this.totalAmount,
    required this.weightKgPerPerson,
    required this.totalWeightKg,
  });

  /// Fitra payable for one person: [weightKgPerPerson] × price per kg.
  final double perPersonAmount;

  /// [perPersonAmount] × number of people.
  final double totalAmount;

  /// Per-person staple weight (kg) used for the calculation.
  final double weightKgPerPerson;

  /// [weightKgPerPerson] × number of people.
  final double totalWeightKg;
}

/// Pure Sadaqatul Fitr math (domain logic is static, side-effect free and
/// exhaustively tested). No rounding is applied — presentation formats.
abstract final class FitraCalculator {
  /// Approximate per-person staple weight (kg). Half a sa' (≈ 1.65 kg) for
  /// wheat/flour per the common Hanafi position; a full sa' (≈ 3.30 kg) for
  /// barley, dates and raisins.
  static const Map<FitraStaple, double> weightKgPerPerson = {
    FitraStaple.wheat: 1.65,
    FitraStaple.flour: 1.65,
    FitraStaple.barley: 3.30,
    FitraStaple.dates: 3.30,
    FitraStaple.raisins: 3.30,
  };

  /// Computes the Fitra result for [input].
  ///
  /// Price per kg is clamped to ≥ 0 and number of people to ≥ 0, so negative
  /// input can never produce a negative amount. A zero price yields a zero
  /// amount while still reporting the staple weight.
  static FitraResult calculate(FitraInput input) {
    final price = input.pricePerKg < 0 ? 0.0 : input.pricePerKg;
    final people = input.numberOfPeople < 0 ? 0 : input.numberOfPeople;
    final kgPerPerson = input.staple.kgPerPerson;

    final perPersonAmount = kgPerPerson * price;

    return FitraResult(
      perPersonAmount: perPersonAmount,
      totalAmount: perPersonAmount * people,
      weightKgPerPerson: kgPerPerson,
      totalWeightKg: kgPerPerson * people,
    );
  }
}
