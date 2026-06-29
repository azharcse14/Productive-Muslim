import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/qibla/domain/usecases/compass_math.dart';

/// Shortest circular distance between two headings (independent of the
/// implementation under test), for wrap-safe ≈0°/≈360° assertions.
double _circularDelta(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  group('qiblaBearing', () {
    test('Dhaka points west-northwest (≈278.5°)', () {
      expect(
        CompassMath.qiblaBearing(23.7104, 90.4074),
        closeTo(278.5, 1.5),
      );
    });

    test('New York points northeast (≈58.5°)', () {
      expect(
        CompassMath.qiblaBearing(40.7128, -74.0060),
        closeTo(58.5, 1.5),
      );
    });

    test('London points east-southeast (≈119°)', () {
      expect(
        CompassMath.qiblaBearing(51.5074, -0.1278),
        closeTo(119, 1.5),
      );
    });

    test('Jakarta points west-northwest (≈295°)', () {
      expect(
        CompassMath.qiblaBearing(-6.2088, 106.8456),
        closeTo(295, 1.5),
      );
    });

    test('a point due south on the Kaaba meridian points due north', () {
      expect(
        _circularDelta(CompassMath.qiblaBearing(10.0, 39.8262), 0),
        lessThan(1.5),
      );
    });

    test('result is always within [0, 360)', () {
      const samples = [
        (23.7104, 90.4074),
        (40.7128, -74.0060),
        (-33.8688, 151.2093),
        (64.1466, -21.9426),
        (-54.8019, -68.3030),
        (0.0, 180.0),
        (89.9, 0.0),
        (-89.9, 0.0),
      ];
      for (final (lat, lng) in samples) {
        final b = CompassMath.qiblaBearing(lat, lng);
        expect(b, greaterThanOrEqualTo(0), reason: '($lat,$lng) → $b');
        expect(b, lessThan(360), reason: '($lat,$lng) → $b');
      }
    });
  });

  group('distanceToKaabaKm', () {
    test('Dhaka is ≈5,173 km away (haversine, R=6371)', () {
      final d = CompassMath.distanceToKaabaKm(23.7104, 90.4074);
      expect(d, greaterThan(5100));
      expect(d, lessThan(5250));
    });

    test('Kaaba itself is ≈0 km', () {
      expect(
        CompassMath.distanceToKaabaKm(
          CompassMath.kaabaLat,
          CompassMath.kaabaLng,
        ),
        lessThan(1),
      );
    });

    test('never exceeds half the Earth circumference (antipode)', () {
      final d = CompassMath.distanceToKaabaKm(
        -CompassMath.kaabaLat,
        CompassMath.kaabaLng - 180,
      );
      expect(d, lessThan(20016));
      expect(d, greaterThan(20000));
    });
  });

  group('angularDifference', () {
    test('simple clockwise step: 10 → 20 is +10', () {
      expect(CompassMath.angularDifference(10, 20), closeTo(10, 1e-9));
    });

    test('wraps clockwise across north: 350 → 10 is +20', () {
      expect(CompassMath.angularDifference(350, 10), closeTo(20, 1e-9));
    });

    test('wraps counter-clockwise across north: 10 → 350 is −20', () {
      expect(CompassMath.angularDifference(10, 350), closeTo(-20, 1e-9));
    });

    test('exact opposite returns +180 (half-open range)', () {
      expect(CompassMath.angularDifference(0, 180), closeTo(180, 1e-9));
      expect(CompassMath.angularDifference(90, 270), closeTo(180, 1e-9));
    });

    test('sign convention: positive clockwise, negative counter-clockwise',
        () {
      expect(CompassMath.angularDifference(0, 90), closeTo(90, 1e-9));
      expect(CompassMath.angularDifference(90, 0), closeTo(-90, 1e-9));
      expect(CompassMath.angularDifference(45, 44), closeTo(-1, 1e-9));
    });

    test('identical angles give 0, including unnormalized inputs', () {
      expect(CompassMath.angularDifference(123.4, 123.4), 0);
      expect(CompassMath.angularDifference(0, 360), 0);
      expect(CompassMath.angularDifference(-90, 270), 0);
    });

    test('never leaves (−180, 180] over a sweep of pairs', () {
      for (var from = 0.0; from < 360; from += 7.3) {
        for (var to = 0.0; to < 360; to += 11.7) {
          final d = CompassMath.angularDifference(from, to);
          expect(d, greaterThan(-180), reason: '$from → $to gave $d');
          expect(d, lessThanOrEqualTo(180), reason: '$from → $to gave $d');
        }
      }
    });
  });

  group('isAligned', () {
    test('exact match is aligned', () {
      expect(CompassMath.isAligned(120, 120), isTrue);
    });

    test('within the default ±3° tolerance', () {
      expect(CompassMath.isAligned(120, 123), isTrue);
      expect(CompassMath.isAligned(123, 120), isTrue);
      expect(CompassMath.isAligned(120, 122.9), isTrue);
    });

    test('just outside the default tolerance is not aligned', () {
      expect(CompassMath.isAligned(120, 123.1), isFalse);
      expect(CompassMath.isAligned(123.1, 120), isFalse);
    });

    test('works across the 0/360 wrap in both directions', () {
      expect(CompassMath.isAligned(359, 1), isTrue);
      expect(CompassMath.isAligned(1, 359), isTrue);
      expect(CompassMath.isAligned(358, 2), isFalse);
    });

    test('honours a custom tolerance', () {
      expect(CompassMath.isAligned(10, 20, toleranceDeg: 10), isTrue);
      expect(CompassMath.isAligned(10, 20.1, toleranceDeg: 10), isFalse);
      expect(CompassMath.isAligned(359, 1, toleranceDeg: 1), isFalse);
    });
  });

  group('smoothHeading', () {
    test('moves a fraction of the way toward the target', () {
      expect(CompassMath.smoothHeading(0, 100), closeTo(15, 1e-9));
      expect(
        CompassMath.smoothHeading(0, 100, factor: 0.5),
        closeTo(50, 1e-9),
      );
    });

    test('repeated application converges toward the target', () {
      var h = 90.0;
      for (var i = 0; i < 200; i++) {
        h = CompassMath.smoothHeading(h, 270);
      }
      expect(_circularDelta(h, 270), lessThan(0.01));
    });

    test('359 → 1 interpolates through 0, not the long way', () {
      final h = CompassMath.smoothHeading(359, 1);
      // Shortest arc is +2°; one step of 0.15 lands at 359.3 — i.e. either
      // still just below 360 or (for larger factors) just past 0.
      expect(h > 359 || h < 0.15 * 2, isTrue, reason: 'got $h');
      expect(h, closeTo(359.3, 1e-9));
      // And never anywhere near the 180° long-way path.
      expect(_circularDelta(h, 180), greaterThan(90));
    });

    test('1 → 359 interpolates backwards through 0', () {
      expect(CompassMath.smoothHeading(1, 359), closeTo(0.7, 1e-9));
    });

    test('factor 1 jumps straight to the target', () {
      expect(CompassMath.smoothHeading(45, 270, factor: 1), closeTo(270, 1e-9));
      expect(CompassMath.smoothHeading(359, 1, factor: 1), closeTo(1, 1e-9));
    });

    test('output is always within [0, 360)', () {
      for (var prev = 0.0; prev < 360; prev += 23.7) {
        for (var next = 0.0; next < 360; next += 31.1) {
          final h = CompassMath.smoothHeading(prev, next);
          expect(h, greaterThanOrEqualTo(0), reason: '$prev → $next gave $h');
          expect(h, lessThan(360), reason: '$prev → $next gave $h');
        }
      }
    });
  });

  group('tiltCompensatedHeading', () {
    // Synthetic northern-hemisphere field: horizontal component H toward
    // magnetic north, vertical component Z pointing into the ground
    // (downward dip). Device flat, screen up: gravity reaction is +z
    // (az ≈ +9.8), "down" is −z, so the field's vertical part reads
    // mz = −Z; with the top edge at magnetic north the horizontal part
    // lies along the device's +y axis (my = +H).
    const g = 9.8;
    const h = 30.0; // µT, horizontal field strength
    const z = 40.0; // µT, downward field strength

    double flatHeading(double headingDeg) {
      // Rotate the device clockwise by headingDeg while flat: the field's
      // horizontal component, expressed in device axes, swings accordingly.
      final psi = headingDeg * math.pi / 180;
      return CompassMath.tiltCompensatedHeading(
        ax: 0,
        ay: 0,
        az: g,
        mx: -h * math.sin(psi),
        my: h * math.cos(psi),
        mz: -z,
      );
    }

    test('flat, top edge at magnetic north → ≈0°', () {
      expect(_circularDelta(flatHeading(0), 0), lessThan(2));
    });

    test('flat, top edge east → ≈90°', () {
      expect(flatHeading(90), closeTo(90, 2));
    });

    test('flat, top edge south → ≈180°', () {
      expect(flatHeading(180), closeTo(180, 2));
    });

    test('flat, top edge west → ≈270°', () {
      expect(flatHeading(270), closeTo(270, 2));
    });

    test('pitched up 30° while pointing north still reads ≈0°', () {
      // Top edge raised 30°: gravity reaction shifts into +y, and the
      // field's components rotate into the device's y/z axes.
      const theta = 30 * math.pi / 180;
      final heading = CompassMath.tiltCompensatedHeading(
        ax: 0,
        ay: g * math.sin(theta),
        az: g * math.cos(theta),
        mx: 0,
        my: h * math.cos(theta) - z * math.sin(theta),
        mz: -h * math.sin(theta) - z * math.cos(theta),
      );
      expect(_circularDelta(heading, 0), lessThan(2));
    });

    test('output is normalized to [0, 360)', () {
      for (var deg = 0.0; deg < 360; deg += 15) {
        final out = flatHeading(deg);
        expect(out, greaterThanOrEqualTo(0));
        expect(out, lessThan(360));
        expect(_circularDelta(out, deg), lessThan(2));
      }
    });
  });

  group('cardinal16', () {
    test('north bin is centred on 0° and 22.5° wide', () {
      expect(CompassMath.cardinal16(0), 'N');
      expect(CompassMath.cardinal16(11.24), 'N');
      expect(CompassMath.cardinal16(11.26), 'NNE');
      expect(CompassMath.cardinal16(359), 'N');
      expect(CompassMath.cardinal16(348.76), 'N');
    });

    test('cardinal and intercardinal points', () {
      expect(CompassMath.cardinal16(90), 'E');
      expect(CompassMath.cardinal16(180), 'S');
      expect(CompassMath.cardinal16(270), 'W');
      expect(CompassMath.cardinal16(45), 'NE');
      expect(CompassMath.cardinal16(225), 'SW');
    });

    test('278° falls in the W bin (258.75°–281.25°)', () {
      expect(CompassMath.cardinal16(278), 'W');
      expect(CompassMath.cardinal16(277.99), 'W');
      expect(CompassMath.cardinal16(281.26), 'WNW');
    });

    test('every point is reachable at its centre', () {
      const expected = [
        'N', 'NNE', 'NE', 'ENE', //
        'E', 'ESE', 'SE', 'SSE',
        'S', 'SSW', 'SW', 'WSW',
        'W', 'WNW', 'NW', 'NNW',
      ];
      for (var i = 0; i < 16; i++) {
        expect(CompassMath.cardinal16(i * 22.5), expected[i]);
      }
    });
  });
}
