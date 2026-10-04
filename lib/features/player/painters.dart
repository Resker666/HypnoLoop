import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'geometry.dart';
import 'playback_clock.dart';
import 'settings.dart';

class SpiralPainter extends CustomPainter {
  SpiralPainter({required this.settings, required this.clock})
    : super(repaint: clock);
  final AppSettings settings;
  final PlaybackClock clock;
  Size? _cachedSize;
  List<Path> _paths = [];
  final Path _heart = buildUnitHeartPath();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(settings.backgroundArgb),
    );
    if (_cachedSize != size) {
      _cachedSize = size;
      _paths = buildSpiralPaths(size, settings.stripes, settings.density);
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(
      (settings.clockwise ? 1 : -1) *
          2 *
          math.pi *
          (clock.animationSeconds % 12) /
          12,
    );
    final paint = Paint()..color = Color(settings.foregroundArgb);
    for (final path in _paths) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
    if (settings.showCenterHeart) {
      final bounds = _heart.getBounds();
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(
        size.shortestSide * settings.centerHeartFraction / bounds.width,
      );
      canvas.translate(-bounds.center.dx, -bounds.center.dy);
      canvas.drawPath(_heart, Paint()..color = Color(settings.heartArgb));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SpiralPainter oldDelegate) =>
      oldDelegate.settings != settings || oldDelegate.clock != clock;
}

class HeartsPainter extends CustomPainter {
  HeartsPainter({required this.settings, required this.clock})
    : super(repaint: clock);
  final AppSettings settings;
  final PlaybackClock clock;
  Size? _cachedSize;
  Path? _heart;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(settings.backgroundArgb),
    );
    if (_cachedSize != size) {
      _cachedSize = size;
      _heart = buildHeartRingPath(size);
    }
    final rings = heartRings(
      size,
      clock.animationSeconds,
      settings.heartIntervalSeconds,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    // Expanding a stroke offsets its contour by a fixed distance; scaling the
    // whole heart would enlarge its cleft and produce the former tunnel shape.
    for (final ring in rings) {
      paint
        ..color = Color(settings.foregroundArgb)
        ..strokeWidth = ring.outerRadius * 2;
      canvas.drawPath(_heart!, paint);
      if (ring.innerRadius > 0) {
        paint
          ..color = Color(settings.backgroundArgb)
          ..strokeWidth = ring.innerRadius * 2;
        canvas.drawPath(_heart!, paint);
      }
    }
    paint
      ..color = Color(settings.heartArgb)
      ..strokeWidth = size.shortestSide * 24 / 320;
    canvas.drawPath(_heart!, paint);
    canvas.drawPath(_heart!, Paint()..color = Color(settings.backgroundArgb));
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) =>
      oldDelegate.settings != settings || oldDelegate.clock != clock;
}
