import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/painters.dart';
import 'package:hypnoloop/features/player/playback_clock.dart';
import 'package:hypnoloop/features/player/settings.dart';

void main() {
  for (final hearts in [false, true]) {
    testWidgets('${hearts ? "hearts" : "spiral"} draws colors and resizes', (
      tester,
    ) async {
      final clock = PlaybackClock()..advance(const Duration(seconds: 3));
      addTearDown(clock.dispose);
      final settings = AppSettings.defaults().preset(hearts ? 2 : 1);
      final key = GlobalKey();
      Future<void> draw(Size size) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    painter: hearts
                        ? HeartsPainter(settings: settings, clock: clock)
                        : SpiralPainter(settings: settings, clock: clock),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }

      await draw(const Size(300, 400));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final colors = <int>{};
        for (var i = 0; i < data.length; i += 4) {
          expect(data[i + 3], 255);
          colors.add(
            0xFF000000 | data[i] << 16 | data[i + 1] << 8 | data[i + 2],
          );
        }
        expect(colors, contains(settings.foregroundArgb));
        expect(
          colors,
          contains(hearts ? settings.heartArgb : settings.backgroundArgb),
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '.tools/previews/${hearts ? "hearts" : "spiral"}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      await draw(const Size(500, 250));
      clock.advance(const Duration(seconds: 1));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
