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
  final Path _heart = buildUnitHeartPath();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(settings.backgroundArgb),
    );
    final layers = heartLayers(
      clock.animationSeconds,
      settings.heartIntervalSeconds,
    );
    // The heart has a concave top. This factor covers even portrait corners.
    final radius = coverageRadius(size) * 3.6;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint();
    for (final layer in layers) {
      if (layer.scale == 0) continue;
      canvas.save();
      canvas.scale(radius * layer.scale);
      paint.color = Color(
        layer.colorIndex == 0 ? settings.heartArgb : settings.foregroundArgb,
      );
      canvas.drawPath(_heart, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) =>
      oldDelegate.settings != settings || oldDelegate.clock != clock;
}
