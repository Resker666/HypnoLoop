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
  ..cubicTo(-.80, .44, -.24, .84, 0, .97)
  ..cubicTo(.24, .84, .80, .44, .95, .04)
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
  final count = ((coverageRadius(size) + size.shortestSide) / spacing).ceil();
  double center(int i) => outline + (i + phase) * spacing;
  return [
    for (var i = count; i >= -1; i--)
      if (center(i) + halfWidth > outline)
        HeartRing(math.max(0, center(i) - halfWidth), center(i) + halfWidth),
  ];
}
