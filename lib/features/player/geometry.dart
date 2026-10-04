import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

double coverageRadius(Size size) {
  if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return 0;
  return math.sqrt(size.width * size.width + size.height * size.height) / 2 + 2;
}

List<Path> buildSpiralPaths(Size size, int stripes, double density) {
  final radius = coverageRadius(size);
  if (radius == 0 || stripes < 2 || !density.isFinite || density <= 0) {
    return [];
  }
  final steps = math.max(96, (density * 80).ceil());
  final width = math.pi / stripes;
  Offset point(double r, double angle) =>
      Offset(r * math.cos(angle), r * math.sin(angle));
  return List.generate(stripes, (stripe) {
    final base = stripe * 2 * math.pi / stripes;
    final path = Path()..moveTo(0, 0);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final p = point(radius * t, base + density * 2 * math.pi * t);
      path.lineTo(p.dx, p.dy);
    }
    path.arcTo(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      base + density * 2 * math.pi,
      width,
      false,
    );
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      final p = point(radius * t, base + width + density * 2 * math.pi * t);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  });
}

Path buildUnitHeartPath() => Path()
  ..moveTo(0, -.34)
  ..cubicTo(-.42, -1.02, -1.23, -.66, -.95, .04)
  ..cubicTo(-.79, .44, -.24, .84, 0, .97)
  ..cubicTo(.24, .84, .79, .44, .95, .04)
  ..cubicTo(1.23, -.66, .42, -1.02, 0, -.34)
  ..close();

Path buildHeartRingPath(Size size) {
  final radius = size.shortestSide * .265;
  return buildUnitHeartPath().transform(
    Float64List.fromList([
      radius,
      0,
      0,
      0,
      0,
      radius,
      0,
      0,
      0,
      0,
      1,
      0,
      size.width / 2,
      size.height * .455,
      0,
      1,
    ]),
  );
}

class HeartRingContours {
  HeartRingContours(this.size) {
    final radius = size.shortestSide * .265;
    for (final curve in [
      const [
        Offset(0, -.34),
        Offset(-.42, -1.02),
        Offset(-1.23, -.66),
        Offset(-.95, .04),
      ],
      const [
        Offset(-.95, .04),
        Offset(-.79, .44),
        Offset(-.24, .84),
        Offset(0, .97),
      ],
    ]) {
      for (var i = 0; i <= 48; i++) {
        if (_points.isNotEmpty && i == 0) continue;
        final t = i / 48, u = 1 - t;
        final p =
            curve[0] * (u * u * u) +
            curve[1] * (3 * u * u * t) +
            curve[2] * (3 * u * t * t) +
            curve[3] * (t * t * t);
        final tangent =
            (curve[1] - curve[0]) * (3 * u * u) +
            (curve[2] - curve[1]) * (6 * u * t) +
            (curve[3] - curve[2]) * (3 * t * t);
        _points.add(p * radius);
        _normals.add(Offset(-tangent.dy, tangent.dx) / tangent.distance);
      }
    }
    final startAngle = math.atan2(.24, -.13);
    for (var i = 1; i <= 16; i++) {
      final angle = startAngle + (math.pi / 2 - startAngle) * i / 16;
      _points.add(Offset(0, .97 * radius));
      _normals.add(Offset(i == 16 ? 0 : math.cos(angle), math.sin(angle)));
    }
  }

  final Size size;
  final _points = <Offset>[], _normals = <Offset>[];

  Path offset(double distance) {
    final left = <Offset>[];
    Offset? previous;
    for (var i = 0; i < _points.length; i++) {
      final p = _points[i] + _normals[i] * distance;
      if (left.isEmpty) {
        if (p.dx > 0) {
          previous = p;
          continue;
        }
        // Clip the concave cleft where the mirrored offset curves intersect.
        // Keeping that inward loop would create a small hole in the pink ring.
        final crossY = previous == null
            ? p.dy
            : previous.dy +
                  (p.dy - previous.dy) * previous.dx / (previous.dx - p.dx);
        left.add(Offset(0, crossY));
      }
      left.add(p);
    }
    final cx = size.width / 2, cy = size.height * .455;
    final path = Path()..moveTo(cx, cy + left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(cx + p.dx, cy + p.dy);
    }
    for (final p in left.reversed.skip(1)) {
      path.lineTo(cx - p.dx, cy + p.dy);
    }
    return path..close();
  }
}

class HeartRing {
  const HeartRing(this.innerRadius, this.outerRadius);
  final double innerRadius, outerRadius;
}

List<HeartRing> heartRings(
  Size size,
  double animationSeconds,
  double intervalSeconds,
) {
  if (size.isEmpty ||
      !size.width.isFinite ||
      !size.height.isFinite ||
      !animationSeconds.isFinite ||
      animationSeconds < 0 ||
      !intervalSeconds.isFinite ||
      intervalSeconds <= 0) {
    return [];
  }
  final interval = intervalSeconds.clamp(.4, 2.0);
  final phase = (animationSeconds % interval) / interval;
  final spacing = size.shortestSide * 35 / 320;
  final halfWidth = size.shortestSide * 13 / 640;
  final outline = size.shortestSide * 12 / 320;
  final farCorner =
      math.sqrt(
        size.width * size.width / 4 + size.height * size.height * .545 * .545,
      ) +
      2;
  final count = (farCorner / spacing).ceil();
  double center(int i) => outline + (i + phase) * spacing;
  return [
    for (var i = count; i >= -1; i--)
      if (center(i) + halfWidth > outline)
        HeartRing(math.max(0, center(i) - halfWidth), center(i) + halfWidth),
  ];
}
