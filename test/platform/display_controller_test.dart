import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/platform/display_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hypnoloop/display');
  test(
    'display requests fullscreen and awake independently, then restores',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final display = DisplayController();
      await display.apply(fullscreen: true, keepAwake: true);
      await display.apply(fullscreen: true, keepAwake: false);
      await display.restore();
      expect(calls[0].arguments, {'fullscreen': true, 'keepAwake': true});
      expect(calls[1].arguments, {'fullscreen': true, 'keepAwake': false});
      expect(calls.last.method, 'restore');
    },
  );
}
