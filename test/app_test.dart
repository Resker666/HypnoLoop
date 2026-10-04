import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/app.dart';
import 'package:hypnoloop/platform/display_controller.dart';
import 'features/player/settings_controller_test.dart' show MemoryStore;

class AppDisplay extends DisplayController {
  @override
  Future<void> apply({
    required bool fullscreen,
    required bool keepAwake,
  }) async {}
  @override
  Future<void> restore() async {}
}

void main() {
  testWidgets('actual app restores selected mode after closing and opening', (
    tester,
  ) async {
    final store = MemoryStore();
    // Windows system fonts are for visual QA only; no font is bundled in APK.
    for (final entry in [
      ('Roboto', 'C:/Windows/Fonts/msyh.ttc'),
      (
        'MaterialIcons',
        '.tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final file = File(entry.$2);
      if (file.existsSync()) {
        final loader = FontLoader(entry.$1)
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await loader.load();
      }
    }
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    final capture = GlobalKey();
    Future<void> open() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: HypnoLoopApp(store: store, display: AppDisplay()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    await open();
    expect(find.text('HypnoLoop'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, '粉紫'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final boundary =
        capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final file = File('.tools/previews/player.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(store.value, isNotNull);
    await open();
    expect(find.text('扩散间隔'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
