import 'dart:math' as math;

/// Inputs for a Qaza (missed obligatory prayer) estimate.
///
/// The estimate covers a continuous period — typically from the age salah
/// became fard until one began praying regularly — and assumes every daily
/// prayer in that window was missed, minus any already made up.
///
/// Dates are treated as date-only (the time component is ignored) and the
/// range is **inclusive** of both [startDate] and [endDate]: a start equal
/// to the end counts as one day. If [endDate] falls before [startDate] the
/// result is empty (everything 0) rather than negative.
final class QazaInput {
  const QazaInput({
    required this.startDate,
    required this.endDate,
    this.includeWitr = false,
    this.alreadyMadeUpPerPrayer = 0,
  });

  /// First day of the missed period (date-only; inclusive).
  final DateTime startDate;

  /// Last day of the missed period (date-only; inclusive).
  final DateTime endDate;

  /// Whether to count Witr as a sixth daily prayer. Witr is wajib in the
  /// Hanafi school, so users following it may wish to make it up too.
  final bool includeWitr;

  /// Prayers of each kind the user has *already* made up. Subtracted from
  /// the per-prayer count; clamped so it can never push a count negative.
  final int alreadyMadeUpPerPrayer;
}

/// Outcome of [QazaCalculator.calculate].
final class QazaResult {
  const QazaResult({
    required this.days,
    required this.perPrayer,
    required this.witr,
    required this.totalMissed,
    required this.breakdown,
  });

  /// Whole days in the period, inclusive of both endpoints (0 when the
  /// range is inverted).
  final int days;

  /// Outstanding count for each of the five daily prayers, after
  /// subtracting [QazaInput.alreadyMadeUpPerPrayer] (floored at 0).
  final int perPrayer;

  /// Outstanding Witr count — equals [perPrayer] when included, else 0.
  final int witr;

  /// `perPrayer * 5 + witr`.
  final int totalMissed;

  /// Per-prayer counts: 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha', and
  /// 'witr' (only present when [QazaInput.includeWitr] is true).
  final Map<String, int> breakdown;
}

/// Pure Qaza math: static, side-effect free, exhaustively tested.
///
/// Convention (see [QazaInput]): date-only and inclusive of both endpoints.
abstract final class QazaCalculator {
  /// The five obligatory daily prayers, in order.
  static const List<String> dailyPrayers = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Computes the Qaza estimate for [input].
  ///
  /// `days` is the inclusive day span (difference in whole days + 1) using
  /// date-only values. An inverted range yields an empty result. Negative
  /// already-made-up counts and resulting negatives are clamped to 0.
  static QazaResult calculate(QazaInput input) {
    final start = _dateOnly(input.startDate);
    final end = _dateOnly(input.endDate);

    if (end.isBefore(start)) {
      return const QazaResult(
        days: 0,
        perPrayer: 0,
        witr: 0,
        totalMissed: 0,
        breakdown: {},
      );
    }

    final days = end.difference(start).inDays + 1;
    final madeUp = math.max(0, input.alreadyMadeUpPerPrayer);
    final perPrayer = math.max(0, days - madeUp);
    final witr = input.includeWitr ? perPrayer : 0;
    final totalMissed = perPrayer * 5 + witr;

    final breakdown = <String, int>{
      for (final prayer in dailyPrayers) prayer: perPrayer,
    };
    if (input.includeWitr) {
      breakdown['witr'] = witr;
    }

    return QazaResult(
      days: days,
      perPrayer: perPrayer,
      witr: witr,
      totalMissed: totalMissed,
      breakdown: breakdown,
    );
  }

  /// Strips the time component, keeping only year/month/day.
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
