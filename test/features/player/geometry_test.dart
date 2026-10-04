import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/geometry.dart';

void main() {
  test(
    'spiral covers diagonal and recalculates for rotated and empty sizes',
    () {
      expect(coverageRadius(const Size(300, 400)), greaterThanOrEqualTo(250));
      expect(
        coverageRadius(const Size(400, 300)),
        coverageRadius(const Size(300, 400)),
      );
      expect(buildSpiralPaths(Size.zero, 4, 3), isEmpty);
      for (final stripes in [2, 8]) {
        for (final density in [1.0, 5.0]) {
          final paths = buildSpiralPaths(
            const Size(300, 400),
            stripes,
            density,
          );
          expect(paths, hasLength(stripes));
          for (final path in paths) {
            final bounds = path.getBounds();
            expect(bounds.isFinite, true);
            expect(bounds.longestSide, greaterThan(250));
          }
        }
      }
    },
  );
  test('unit heart is closed, finite and left-right symmetric', () {
    final path = buildUnitHeartPath();
    final bounds = path.getBounds();
    expect(bounds.center.dx, closeTo(0, 1e-6));
    expect(bounds.width, greaterThan(0));
    expect(bounds.height, greaterThan(0));
    expect(path.computeMetrics().single.isClosed, true);
  });
  test('heart ring radii stay finite and bounded at large times', () {
    for (final interval in [.4, 1.0, 2.0]) {
      final rings = heartRings(const Size(320, 640), 1000000.25, interval);
      expect(rings.length, lessThanOrEqualTo(22));
      expect(rings, isNotEmpty);
      expect(
        rings.map((value) => value.outerRadius),
        heartRings(
          const Size(320, 640),
          1000000.25,
          interval,
        ).map((value) => value.outerRadius),
      );
      for (final ring in rings) {
        expect(ring.innerRadius.isFinite, true);
        expect(ring.outerRadius.isFinite, true);
        expect(ring.innerRadius, greaterThanOrEqualTo(0));
        expect(ring.outerRadius, greaterThan(ring.innerRadius));
      }
    }
    expect(heartRings(const Size(320, 640), 1, 0), isEmpty);
    expect(heartRings(Size.zero, 1, 1), isEmpty);
    expect(heartRings(const Size(320, 640), double.nan, 1), isEmpty);
  });
}
