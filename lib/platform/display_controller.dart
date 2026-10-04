import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DisplayController {
  static const _channel = MethodChannel('hypnoloop/display');

  Future<void> apply({
    required bool fullscreen,
    required bool keepAwake,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('apply', {
        'fullscreen': fullscreen,
        'keepAwake': keepAwake,
      });
    }
  }

  Future<void> restore() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('restore');
    }
  }
}
