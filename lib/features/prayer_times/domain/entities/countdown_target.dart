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

  /// [instantOf] maps a wall time to its real instant (the location's
  /// zone), so a DST shift on the device doesn't skew the difference.
  Duration remainingAt(DateTime now, [DateTime Function(DateTime)? instantOf]) {
    final i = instantOf ?? _wall;
    return i(at).difference(i(now));
  }

  /// 0..1 elapsed fraction of the window at [now].
  double progressAt(DateTime now, [DateTime Function(DateTime)? instantOf]) {
    final i = instantOf ?? _wall;
    final start = i(windowStart);
    final total = i(at).difference(start).inSeconds;
    if (total <= 0) {
      return 1;
    }
    final elapsed = i(now).difference(start).inSeconds;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  static DateTime _wall(DateTime t) => t;

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
