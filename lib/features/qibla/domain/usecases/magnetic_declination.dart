import 'dart:math' as math;

/// Magnetic declination (true north − magnetic north) from the World
/// Magnetic Model WMM2025 (NOAA/BGS, epoch 2025.0, valid 2025–2030).
///
/// The phone magnetometer gives a heading relative to magnetic north while
/// [CompassMath.qiblaBearing] is relative to true north; adding the
/// declination converts one into the other. Pure Dart so it works offline
/// on every platform. Spherical-harmonic synthesis per the WMM2025
/// technical report (degree/order 12, geodetic → geocentric on WGS-84).
abstract final class MagneticDeclination {
  static const _epoch = 2025.0;
  static const _maxN = 12;
  static const _refRadiusKm = 6371.2;
  static const _wgs84A = 6378.137;
  static const _wgs84F = 1 / 298.257223563;
  static const _deg2rad = math.pi / 180;

  /// Declination in degrees (east positive) at geodetic [latitude] /
  /// [longitude], sea level ([altitudeKm] above the ellipsoid), on [date].
  // ponytail: past 2030 this extrapolates the secular variation; swap in
  // the next WMM coefficients when NOAA publishes them.
  static double at(
    double latitude,
    double longitude,
    DateTime date, {
    double altitudeKm = 0,
  }) {
    final utc = date.toUtc();
    final yearStart = DateTime.utc(utc.year);
    final yearSeconds = DateTime.utc(utc.year + 1).difference(yearStart);
    final year =
        utc.year + utc.difference(yearStart).inSeconds / yearSeconds.inSeconds;
    return atDecimalYear(latitude, longitude, year, altitudeKm: altitudeKm);
  }

  /// [at] with an explicit decimal year (e.g. 2025.5), as in NOAA's test
  /// values.
  static double atDecimalYear(
    double latitude,
    double longitude,
    double year, {
    double altitudeKm = 0,
  }) {
    final dt = year - _epoch;
    // Geodetic → geocentric spherical coordinates (WGS-84).
    final lat = latitude.clamp(-89.99999, 89.99999) * _deg2rad;
    const e2 = _wgs84F * (2 - _wgs84F);
    final sinLat = math.sin(lat);
    final rc = _wgs84A / math.sqrt(1 - e2 * sinLat * sinLat);
    final p = (rc + altitudeKm) * math.cos(lat);
    final z = (rc * (1 - e2) + altitudeKm) * sinLat;
    final r = math.sqrt(p * p + z * z);
    final gcLat = math.asin(z / r);
    final lon = longitude * _deg2rad;

    // Schmidt semi-normalised associated Legendre functions of sin(gcLat)
    // and their derivatives w.r.t. colatitude θ = π/2 − gcLat.
    final cosT = math.sin(gcLat);
    final sinT = math.cos(gcLat);
    final pnm = List.generate(_maxN + 1, (_) => List.filled(_maxN + 1, 0.0));
    final dp = List.generate(_maxN + 1, (_) => List.filled(_maxN + 1, 0.0));
    pnm[0][0] = 1;
    for (var n = 1; n <= _maxN; n++) {
      for (var m = 0; m <= n; m++) {
        if (n == m) {
          pnm[n][m] = sinT * pnm[n - 1][m - 1];
          dp[n][m] = cosT * pnm[n - 1][m - 1] + sinT * dp[n - 1][m - 1];
        } else if (n == 1 || m == n - 1) {
          pnm[n][m] = cosT * pnm[n - 1][m];
          dp[n][m] = -sinT * pnm[n - 1][m] + cosT * dp[n - 1][m];
        } else {
          final k = ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3));
          pnm[n][m] = cosT * pnm[n - 1][m] - k * pnm[n - 2][m];
          dp[n][m] =
              -sinT * pnm[n - 1][m] + cosT * dp[n - 1][m] - k * dp[n - 2][m];
        }
      }
    }
    // Gauss → Schmidt normalisation factors.
    final s = List.generate(_maxN + 1, (_) => List.filled(_maxN + 1, 0.0));
    s[0][0] = 1;
    for (var n = 1; n <= _maxN; n++) {
      s[n][0] = s[n - 1][0] * (2 * n - 1) / n;
      for (var m = 1; m <= n; m++) {
        s[n][m] =
            s[n][m - 1] * math.sqrt((n - m + 1) * (m == 1 ? 2 : 1) / (n + m));
      }
    }

    // Field components in the geocentric frame (north, east, down).
    var x = 0.0;
    var y = 0.0;
    var zDown = 0.0;
    final ratio = _refRadiusKm / r;
    for (final c in _coefficients) {
      final n = c[0].toInt();
      final m = c[1].toInt();
      final g = c[2] + dt * c[4];
      final h = c[3] + dt * c[5];
      final rr = math.pow(ratio, n + 2);
      final cosM = math.cos(m * lon);
      final sinM = math.sin(m * lon);
      final pn = pnm[n][m] * s[n][m];
      final dpn = dp[n][m] * s[n][m];
      x += rr * (g * cosM + h * sinM) * dpn;
      y += rr * m * (g * sinM - h * cosM) * pn / sinT;
      zDown -= (n + 1) * rr * (g * cosM + h * sinM) * pn;
    }
    // Rotate north component back into the geodetic frame.
    final diff = lat - gcLat;
    final north = x * math.cos(diff) + zDown * math.sin(diff);
    return math.atan2(y, north) / _deg2rad;
  }

  /// WMM2025 Gauss coefficients: n, m, g, h (nT), ġ, ḣ (nT/yr). Verbatim
  /// from NOAA's WMM.COF (released 2024-11-13).
  static const List<List<num>> _coefficients = [
    [1, 0, -29351.8, 0.0, 12.0, 0.0],
    [1, 1, -1410.8, 4545.4, 9.7, -21.5],
    [2, 0, -2556.6, 0.0, -11.6, 0.0],
    [2, 1, 2951.1, -3133.6, -5.2, -27.7],
    [2, 2, 1649.3, -815.1, -8.0, -12.1],
    [3, 0, 1361.0, 0.0, -1.3, 0.0],
    [3, 1, -2404.1, -56.6, -4.2, 4.0],
    [3, 2, 1243.8, 237.5, 0.4, -0.3],
    [3, 3, 453.6, -549.5, -15.6, -4.1],
    [4, 0, 895.0, 0.0, -1.6, 0.0],
    [4, 1, 799.5, 278.6, -2.4, -1.1],
    [4, 2, 55.7, -133.9, -6.0, 4.1],
    [4, 3, -281.1, 212.0, 5.6, 1.6],
    [4, 4, 12.1, -375.6, -7.0, -4.4],
    [5, 0, -233.2, 0.0, 0.6, 0.0],
    [5, 1, 368.9, 45.4, 1.4, -0.5],
    [5, 2, 187.2, 220.2, 0.0, 2.2],
    [5, 3, -138.7, -122.9, 0.6, 0.4],
    [5, 4, -142.0, 43.0, 2.2, 1.7],
    [5, 5, 20.9, 106.1, 0.9, 1.9],
    [6, 0, 64.4, 0.0, -0.2, 0.0],
    [6, 1, 63.8, -18.4, -0.4, 0.3],
    [6, 2, 76.9, 16.8, 0.9, -1.6],
    [6, 3, -115.7, 48.8, 1.2, -0.4],
    [6, 4, -40.9, -59.8, -0.9, 0.9],
    [6, 5, 14.9, 10.9, 0.3, 0.7],
    [6, 6, -60.7, 72.7, 0.9, 0.9],
    [7, 0, 79.5, 0.0, -0.0, 0.0],
    [7, 1, -77.0, -48.9, -0.1, 0.6],
    [7, 2, -8.8, -14.4, -0.1, 0.5],
    [7, 3, 59.3, -1.0, 0.5, -0.8],
    [7, 4, 15.8, 23.4, -0.1, 0.0],
    [7, 5, 2.5, -7.4, -0.8, -1.0],
    [7, 6, -11.1, -25.1, -0.8, 0.6],
    [7, 7, 14.2, -2.3, 0.8, -0.2],
    [8, 0, 23.2, 0.0, -0.1, 0.0],
    [8, 1, 10.8, 7.1, 0.2, -0.2],
    [8, 2, -17.5, -12.6, 0.0, 0.5],
    [8, 3, 2.0, 11.4, 0.5, -0.4],
    [8, 4, -21.7, -9.7, -0.1, 0.4],
    [8, 5, 16.9, 12.7, 0.3, -0.5],
    [8, 6, 15.0, 0.7, 0.2, -0.6],
    [8, 7, -16.8, -5.2, -0.0, 0.3],
    [8, 8, 0.9, 3.9, 0.2, 0.2],
    [9, 0, 4.6, 0.0, -0.0, 0.0],
    [9, 1, 7.8, -24.8, -0.1, -0.3],
    [9, 2, 3.0, 12.2, 0.1, 0.3],
    [9, 3, -0.2, 8.3, 0.3, -0.3],
    [9, 4, -2.5, -3.3, -0.3, 0.3],
    [9, 5, -13.1, -5.2, 0.0, 0.2],
    [9, 6, 2.4, 7.2, 0.3, -0.1],
    [9, 7, 8.6, -0.6, -0.1, -0.2],
    [9, 8, -8.7, 0.8, 0.1, 0.4],
    [9, 9, -12.9, 10.0, -0.1, 0.1],
    [10, 0, -1.3, 0.0, 0.1, 0.0],
    [10, 1, -6.4, 3.3, 0.0, 0.0],
    [10, 2, 0.2, 0.0, 0.1, -0.0],
    [10, 3, 2.0, 2.4, 0.1, -0.2],
    [10, 4, -1.0, 5.3, -0.0, 0.1],
    [10, 5, -0.6, -9.1, -0.3, -0.1],
    [10, 6, -0.9, 0.4, 0.0, 0.1],
    [10, 7, 1.5, -4.2, -0.1, 0.0],
    [10, 8, 0.9, -3.8, -0.1, -0.1],
    [10, 9, -2.7, 0.9, -0.0, 0.2],
    [10, 10, -3.9, -9.1, -0.0, -0.0],
    [11, 0, 2.9, 0.0, 0.0, 0.0],
    [11, 1, -1.5, 0.0, -0.0, -0.0],
    [11, 2, -2.5, 2.9, 0.0, 0.1],
    [11, 3, 2.4, -0.6, 0.0, -0.0],
    [11, 4, -0.6, 0.2, 0.0, 0.1],
    [11, 5, -0.1, 0.5, -0.1, -0.0],
    [11, 6, -0.6, -0.3, 0.0, -0.0],
    [11, 7, -0.1, -1.2, -0.0, 0.1],
    [11, 8, 1.1, -1.7, -0.1, -0.0],
    [11, 9, -1.0, -2.9, -0.1, 0.0],
    [11, 10, -0.2, -1.8, -0.1, 0.0],
    [11, 11, 2.6, -2.3, -0.1, 0.0],
    [12, 0, -2.0, 0.0, 0.0, 0.0],
    [12, 1, -0.2, -1.3, 0.0, -0.0],
    [12, 2, 0.3, 0.7, -0.0, 0.0],
    [12, 3, 1.2, 1.0, -0.0, -0.1],
    [12, 4, -1.3, -1.4, -0.0, 0.1],
    [12, 5, 0.6, -0.0, -0.0, -0.0],
    [12, 6, 0.6, 0.6, 0.1, -0.0],
    [12, 7, 0.5, -0.1, -0.0, -0.0],
    [12, 8, -0.1, 0.8, 0.0, 0.0],
    [12, 9, -0.4, 0.1, 0.0, -0.0],
    [12, 10, -0.2, -1.0, -0.1, -0.0],
    [12, 11, -1.3, 0.1, -0.0, 0.0],
    [12, 12, -0.7, 0.2, -0.1, -0.1],
  ];
}
