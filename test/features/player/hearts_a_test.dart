import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/painters.dart';
import 'package:hypnoloop/features/player/playback_clock.dart';
import 'package:hypnoloop/features/player/settings.dart';

Future<Uint8List> frame(
  double seconds, {
  ui.Size size = const ui.Size(320, 640),
}) async {
  final clock = PlaybackClock()..setSpeed(1);
  clock.advance(Duration(microseconds: (seconds * 1000000).round()));
  final recorder = ui.PictureRecorder();
  HeartsPainter(
    settings: AppSettings.defaults().preset(2),
    clock: clock,
  ).paint(ui.Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final output = File(
    '.tools/previews/heart-rings-${size.width.toInt()}x${size.height.toInt()}-$seconds.png',
  );
  await output.parent.create(recursive: true);
  await output.writeAsBytes(png!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  clock.dispose();
  return bytes;
}

void main() {
  testWidgets('heart rings reproduce approved A contours and spacing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final actual = await frame(.36);
      final codec = await ui.instantiateImageCodec(
        await File('test/fixtures/heart-a.png').readAsBytes(),
      );
      final expectedImage = (await codec.getNextFrame()).image;
      final expected = (await expectedImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      var error = 0, mismatchedPixels = 0;
      for (var i = 0; i < actual.length; i += 4) {
        var pixelError = 0;
        for (var channel = 0; channel < 3; channel++) {
          final difference = (actual[i + channel] - expected[i + channel])
              .abs();
          error += difference;
          pixelError += difference;
        }
        if (pixelError / 3 > 64) mismatchedPixels++;
        expect(actual[i + 3], 255);
      }
      // Allow rasterizer edge antialiasing, while rejecting different contours.
      expect(error / (320 * 640 * 3), lessThan(6));
      expect(mismatchedPixels / (320 * 640), lessThan(.03));
      expectedImage.dispose();
      codec.dispose();
    });
  });
  testWidgets('heart ring loop repeats with a stable white center', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final initial = await frame(0);
      final looped = await frame(1.5);
      expect(looped, orderedEquals(initial));
      for (final seconds in [0.0, .4, 1.49]) {
        final bytes = await frame(seconds);
        final center = (290 * 320 + 160) * 4;
        expect(bytes.sublist(center, center + 4), [255, 255, 255, 255]);
      }
      final landscape = await frame(.36, size: const ui.Size(640, 320));
      final center = (146 * 640 + 320) * 4;
      expect(landscape.sublist(center, center + 4), [255, 255, 255, 255]);
    });
  });
}
