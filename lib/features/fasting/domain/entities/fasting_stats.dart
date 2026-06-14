/// Read-only summary of the personal nafl-fast log. No-shame framing: these
/// are encouragements, never deficits.
final class FastingStats {
  const FastingStats({
    required this.total,
    required this.thisMonth,
    required this.thisHijriMonth,
  });

  /// Every nafl fast ever logged.
  final int total;

  /// Fasts logged in the current Gregorian month.
  final int thisMonth;

  /// Fasts logged in the current hijri month.
  final int thisHijriMonth;
}