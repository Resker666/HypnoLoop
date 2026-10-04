import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/geometry.dart';

void main() {
  test(
    'sparse heart layers keep edge colors continuous across a birth boundary',
    () {
      const size = Size(390, 844);
      final radius = coverageRadius(size) * 3.6;
      final heart = buildUnitHeartPath();
      int colorAt(double time) {
        var color = 0xFF291638;
        for (final layer in heartLayers(time, 2)) {
          if (layer.scale > 0 &&
              heart.contains(Offset(0, -410 / (radius * layer.scale)))) {
            color = layer.colorIndex == 0 ? 0xFFFF8EBD : 0xFF291638;
          }
        }
        return color;
      }

      expect(colorAt(4.001), colorAt(3.999));
      expect(colorAt(8.001), colorAt(7.999));
    },
  );
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
  test('heart layer count stays bounded and phase is deterministic', () {
    for (final interval in [.4, 1.0, 2.0]) {
      final layers = heartLayers(1000000.25, interval);
      expect(layers.length, lessThanOrEqualTo(11));
      expect(layers, isNotEmpty);
      expect(
        layers.map((value) => value.scale),
        heartLayers(1000000.25, interval).map((value) => value.scale),
      );
      for (final layer in layers) {
        expect(layer.scale.isFinite, true);
        expect(layer.scale, inInclusiveRange(0, 1));
        expect(layer.colorIndex, inInclusiveRange(0, 1));
      }
    }
    expect(heartLayers(1, 0), isEmpty);
  });
}
