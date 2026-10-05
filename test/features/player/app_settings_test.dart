import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/app.dart';
import '../../app_test.dart' show AppDisplay;
import 'settings_controller_test.dart' show MemoryStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hypnoloop/project');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pumpWidget(
      HypnoLoopApp(store: MemoryStore(), display: AppDisplay()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('暂停'));
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  }

  // Catches a gear still leading straight to icons or a repository row that
  // cannot launch the project; the platform boundary is the only test double.
  testWidgets(
    'settings exposes author and opens the project then returns home',
    (tester) async {
      addTearDown(() => close(tester));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'getVersion') return '0.1.4';
        if (call.method == 'openProject') return true;
        throw MissingPluginException();
      });
      await open(tester);
      expect(find.text('Resker666'), findsOneWidget);
      expect(find.text('0.1.4'), findsOneWidget);
      expect(find.text('github.com/Resker666/HypnoLoop'), findsOneWidget);
      await tester.tap(find.byKey(const Key('project-address')));
      await tester.pumpAndSettle();
      expect(calls, contains('openProject'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toggle-preview-playback')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  // Catches silently doing nothing when no browser or native opener is present.
  testWidgets(
    'failed project launch copies the address with visible feedback',
    (tester) async {
      addTearDown(() => close(tester));
      String? copied;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getVersion') return '0.1.4';
        throw PlatformException(code: 'no-browser');
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      await open(tester);
      await tester.tap(find.byKey(const Key('project-address')));
      await tester.pumpAndSettle();
      expect(copied, 'https://github.com/Resker666/HypnoLoop');
      expect(find.text('项目地址已复制，可在浏览器打开'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
