import 'dart:math' as math;
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
  ..moveTo(0, -.35)
  ..cubicTo(-.4, -1, -1.25, -.65, -.95, .05)
  ..cubicTo(-.8, .45, -.25, .85, 0, 1)
  ..cubicTo(.25, .85, .8, .45, .95, .05)
  ..cubicTo(1.25, -.65, .4, -1, 0, -.35)
  ..close();

class HeartLayer {
  const HeartLayer(this.scale, this.colorIndex);
  final double scale;
  final int colorIndex;
}

List<HeartLayer> heartLayers(double animationSeconds, double intervalSeconds) {
  if (!animationSeconds.isFinite ||
      animationSeconds < 0 ||
      !intervalSeconds.isFinite ||
      intervalSeconds <= 0) {
    return [];
  }
  final interval = intervalSeconds.clamp(.4, 2.0);
  final birth = (animationSeconds / interval).floor();
  final phase = animationSeconds % interval;
  // Include layers born before time zero so the very first frame is filled.
  final count = (4 / interval).ceil();
  return [
    for (var i = count; i >= 0; i--)
      HeartLayer(((phase + i * interval) / 4).clamp(0.0, 1.0), (birth - i) % 2),
  ];
}
