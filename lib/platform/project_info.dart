import 'package:flutter/services.dart';

class ProjectInfo {
  static const author = 'Resker666';
  static const address = 'https://github.com/Resker666/HypnoLoop';
  static const displayAddress = 'github.com/Resker666/HypnoLoop';
  static const _channel = MethodChannel('hypnoloop/project');

  static Future<String?> version() async {
    try {
      return await _channel.invokeMethod<String>('getVersion');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> open() async {
    try {
      return await _channel.invokeMethod<bool>('openProject') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
