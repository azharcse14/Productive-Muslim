import '../../../settings/domain/entities/prayer_params.dart';

/// What the smart countdown is counting toward (design §4.3).
enum CountdownKind { waqtStart, jamaat, waqtEnd, sahriEnd, iftar }

/// Urgency/visual state of the countdown card. [urgent] is time pressure
/// only — never used for missed deeds (hard product rule).
enum CountdownUrgency { calm, amber, urgent, sahri, iftar }

final class CountdownTarget {
  const CountdownTarget({
    required this.kind,
    required this.prayer,
    required this.at,
    required this.windowStart,
  });

  final CountdownKind kind;

  /// The prayer this target relates to (fajr for sahri, maghrib for iftar).
  final Prayer prayer;

  /// The wall-clock moment being counted down to.
  final DateTime at;

  /// Start of the visual progress window (progress = elapsed/(at−start)).
  final DateTime windowStart;

  Duration remainingAt(DateTime now) => at.difference(now);

  /// 0..1 elapsed fraction of the window at [now].
  double progressAt(DateTime now) {
    final total = at.difference(windowStart).inSeconds;
    if (total <= 0) {
      return 1;
    }
    final elapsed = now.difference(windowStart).inSeconds;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is CountdownTarget &&
      other.kind == kind &&
      other.prayer == prayer &&
      other.at == at &&
      other.windowStart == windowStart;

  @override
  int get hashCode => Object.hash(kind, prayer, at, windowStart);
}
