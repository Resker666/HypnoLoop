import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/player_page.dart';
import 'package:hypnoloop/features/player/playback_clock.dart';
import 'package:hypnoloop/features/player/settings.dart';
import 'package:hypnoloop/platform/display_controller.dart';

class FakeDisplay extends DisplayController {
  final requests = <(bool, bool)>[];
  var restored = false;
  bool fail = false;
  @override
  Future<void> apply({
    required bool fullscreen,
    required bool keepAwake,
  }) async {
    requests.add((fullscreen, keepAwake));
    if (fail) throw PlatformException(code: 'display-failed');
  }

  @override
  Future<void> restore() async {
    restored = true;
  }
}

void main() {
  late PlaybackClock clock;
  late FakeDisplay display;
  late ValueNotifier<AppSettings> settings;
  Future<void> launch(WidgetTester tester) async {
    clock = PlaybackClock();
    display = FakeDisplay();
    settings = ValueNotifier(AppSettings.defaults());
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<AppSettings>(
          valueListenable: settings,
          builder: (context, value, _) => PlayerPage(
            settings: value,
            onSettingsChanged: (value) => settings.value = value,
            onCommitSettings: () async {},
            clock: clock,
            display: display,
          ),
        ),
      ),
    );
    await tester.pump();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      clock.dispose();
      settings.dispose();
    });
  }

  Future<void> fullscreen(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('start-fullscreen')));
    await tester.pump();
  }

  testWidgets(
    'fullscreen sliders update the open sheet without build exceptions',
    (tester) async {
      await launch(tester);
      await fullscreen(tester);
      await tester.tap(find.byKey(const Key('animation-canvas')));
      await tester.pump();
      await tester.tap(find.byTooltip('设置'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.drag(find.byType(Slider).first, const Offset(60, 0));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(settings.value.speed, greaterThan(.5));
      expect(
        tester.widget<Slider>(find.byType(Slider).first).value,
        settings.value.speed,
      );
    },
  );

  testWidgets('fullscreen tap, timeout, modal settings and back order', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('爱心'));
    await tester.pump();
    expect(settings.value.kind, AnimationKind.hearts);
    await fullscreen(tester);
    expect(display.requests.last, (true, true));
    expect(find.byKey(const Key('player-toolbar')), findsNothing);
    await tester.tap(find.byKey(const Key('animation-canvas')));
    await tester.pump();
    expect(find.byKey(const Key('player-toolbar')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('player-toolbar')), findsNothing);
    await tester.tap(find.byKey(const Key('animation-canvas')));
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('播放设置'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('播放设置'), findsNothing);
    expect(find.byKey(const Key('start-fullscreen')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('start-fullscreen')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(display.restored, true);
  });
  testWidgets(
    'pause survives background, resumed clock excludes background time',
    (tester) async {
      await launch(tester);
      await fullscreen(tester);
      await tester.tap(find.byKey(const Key('animation-canvas')));
      await tester.pump();
      await tester.tap(find.byTooltip('暂停'));
      await tester.pump();
      expect(display.requests.last, (true, false));
      final paused = clock.animationSeconds;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(clock.isPlaying, false);
      expect(clock.animationSeconds, paused);
      await tester.tap(find.byKey(const Key('animation-canvas')));
      await tester.pump();
      await tester.tap(find.byTooltip('继续'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final playing = clock.animationSeconds;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(clock.animationSeconds - playing, closeTo(.5, .01));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'landscape settings remain scrollable and display failure allows exit',
    (tester) async {
      await launch(tester);
      display.fail = true;
      await fullscreen(tester);
      expect(find.text('显示模式切换失败'), findsOneWidget);
      await tester.tap(find.byKey(const Key('animation-canvas')));
      await tester.pump();
      await tester.tap(find.byTooltip('设置'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.binding.setSurfaceSize(const Size(800, 320));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const Key('start-fullscreen')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    },
  );
}
