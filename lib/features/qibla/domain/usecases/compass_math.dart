import 'dart:math' as math;

/// Pure compass mathematics for the Qibla feature — bearing, distance,
/// angle arithmetic, heading smoothing and tilt compensation. No sensor
/// or platform dependencies; the presentation layer feeds raw vectors in
/// and renders the angles out.
///
/// All public angles are in DEGREES; headings/bearings are clockwise from
/// north, normalized to [0, 360).
abstract final class CompassMath {
  /// Kaaba latitude (Masjid al-Haram, Makkah).
  static const kaabaLat = 21.4225;

  /// Kaaba longitude.
  static const kaabaLng = 39.8262;

  /// Mean Earth radius (km), for the haversine distance.
  static const _earthRadiusKm = 6371.0;

  static const _deg2rad = math.pi / 180;
  static const _rad2deg = 180 / math.pi;

  /// Great-circle initial bearing from ([latitude], [longitude]) to the
  /// Kaaba, clockwise from true north in [0, 360).
  ///
  /// Standard forward-azimuth formula:
  /// θ = atan2(sin Δλ·cos φ₂, cos φ₁·sin φ₂ − sin φ₁·cos φ₂·cos Δλ).
  static double qiblaBearing(double latitude, double longitude) {
    final phi1 = latitude * _deg2rad;
    const phi2 = kaabaLat * _deg2rad;
    final deltaLambda = (kaabaLng - longitude) * _deg2rad;
    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    return _norm360(math.atan2(y, x) * _rad2deg);
  }

  /// Haversine great-circle distance from ([latitude], [longitude]) to the
  /// Kaaba, in kilometres (mean Earth radius 6371 km).
  static double distanceToKaabaKm(double latitude, double longitude) {
    final phi1 = latitude * _deg2rad;
    const phi2 = kaabaLat * _deg2rad;
    final deltaPhi = (kaabaLat - latitude) * _deg2rad;
    final deltaLambda = (kaabaLng - longitude) * _deg2rad;
    final sinHalfPhi = math.sin(deltaPhi / 2);
    final sinHalfLambda = math.sin(deltaLambda / 2);
    final a =
        sinHalfPhi * sinHalfPhi +
        math.cos(phi1) * math.cos(phi2) * sinHalfLambda * sinHalfLambda;
    return 2 * _earthRadiusKm * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Signed shortest rotation that takes [from] onto [to], in (−180, 180].
  ///
  /// Positive = clockwise. Exactly opposite angles return +180 (never −180),
  /// so the range is half-open as documented.
  static double angularDifference(double from, double to) {
    final diff = _norm360(to - from);
    return diff > 180 ? diff - 360 : diff;
  }

  /// Whether [heading] points at [bearing] within ±[toleranceDeg]
  /// (design: ±3°). Wrap-safe: heading 359° vs bearing 1° is aligned.
  static bool isAligned(
    double heading,
    double bearing, {
    double toleranceDeg = 3,
  }) => angularDifference(heading, bearing).abs() <= toleranceDeg;

  /// Exponential smoothing of a compass heading along the SHORTEST arc:
  /// moves [factor] of the way from [previous] toward [next], so
  /// 359° → 1° interpolates through 0°, never the long way around 180°.
  /// Result normalized to [0, 360).
  static double smoothHeading(
    double previous,
    double next, {
    double factor = 0.15,
  }) => _norm360(previous + factor * angularDifference(previous, next));

  /// Tilt-compensated magnetic heading from raw accelerometer and
  /// magnetometer vectors, in [0, 360) clockwise from magnetic north.
  ///
  /// Axis convention (Flutter sensors_plus, Android-style device frame):
  /// x = right edge, y = top edge, z = out of the screen. A device lying
  /// flat, screen up, reads az ≈ +9.8 (gravity reaction is along +z).
  ///
  /// Orientation model (intrinsic heading → pitch → roll):
  /// - pitch θ about device x, positive when the TOP edge tilts UP, so the
  ///   accelerometer reads ay = g·sinθ, giving
  ///   θ = atan2(ay, √(ax² + az²));
  /// - roll φ about device y, positive when the RIGHT edge dips DOWN, so
  ///   ax = −g·sinφ·cosθ and az = g·cosφ·cosθ, giving
  ///   φ = atan2(−ax, az).
  ///
  /// The magnetometer vector is de-rotated by roll, then pitch, back to the
  /// horizontal plane. In that level frame the field's east component is
  /// −mx′ and its north component is my′ (a level device pointing north
  /// reads the horizontal field along +y), hence
  /// heading = atan2(−mx′, my′): top edge to magnetic north → 0°,
  /// top edge east → 90°.
  static double tiltCompensatedHeading({
    required double ax,
    required double ay,
    required double az,
    required double mx,
    required double my,
    required double mz,
  }) {
    final pitch = math.atan2(ay, math.sqrt(ax * ax + az * az));
    final roll = math.atan2(-ax, az);

    final sinPitch = math.sin(pitch);
    final cosPitch = math.cos(pitch);
    final sinRoll = math.sin(roll);
    final cosRoll = math.cos(roll);

    // Undo roll (about y): bring x/z back under the pitched frame.
    final mxLevel = mx * cosRoll + mz * sinRoll;
    final mzRolled = -mx * sinRoll + mz * cosRoll;
    // Undo pitch (about x): recover the horizontal north component.
    final myLevel = my * cosPitch - mzRolled * sinPitch;

    return _norm360(math.atan2(-mxLevel, myLevel) * _rad2deg);
  }

  static const _windPoints = [
    'N', 'NNE', 'NE', 'ENE', //
    'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW',
    'W', 'WNW', 'NW', 'NNW',
  ];

  /// 16-wind compass point for [bearing] — each point owns a 22.5°-wide
  /// bin centred on it (N covers 348.75°–11.25°). Used by the verbal
  /// sensor-fallback ("Qibla is 278° W").
  static String cardinal16(double bearing) =>
      _windPoints[(_norm360(bearing) / 22.5).round() % 16];

  /// Normalizes [degrees] to [0, 360). Defensive about the floating-point
  /// edge where the remainder rounds up to exactly 360.0.
  static double _norm360(double degrees) {
    final n = degrees % 360;
    if (n < 0) {
      return n + 360;
    }
    return n == 360 ? 0 : n;
  }
}
