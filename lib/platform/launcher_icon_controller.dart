import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum LauncherIcon {
  a('粉白爱心环'),
  b('渐变爱心旋涡'),
  c('黑白螺旋爱心'),
  d('紫粉双环爱心');

  const LauncherIcon(this.label);
  final String label;
  String get letter => name.toUpperCase();
  String get asset => 'assets/launcher_icons/$name.png';
}

class LauncherIconController extends ChangeNotifier {
  static const defaultIcon = LauncherIcon.b;
  static const _channel = MethodChannel('hypnoloop/launcher-icon');
  LauncherIcon? selected;
  bool busy = false, available = false;
  String? error;
  bool _disposed = false;

  LauncherIcon _decode(Object? value) {
    for (final icon in LauncherIcon.values) {
      if (icon.name == value) return icon;
    }
    throw const FormatException('Unknown launcher icon');
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _changed();
    try {
      selected = _decode(await _channel.invokeMethod<String>('getCurrent'));
      available = true;
    } on MissingPluginException {
      selected = null;
      available = false;
      error = '当前平台暂不支持更换桌面图标';
    } catch (_) {
      selected = null;
      available = false;
      error = '无法读取当前图标，请重试';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> select(LauncherIcon icon) async {
    if (busy || !available || _disposed || selected == icon) return;
    busy = true;
    error = null;
    _changed();
    try {
      final actual = _decode(
        await _channel.invokeMethod<String>('setIcon', {'id': icon.name}),
      );
      if (actual != icon) throw const FormatException('Icon switch mismatch');
      selected = actual;
    } catch (_) {
      // A partial platform failure may still change the enabled component.
      // Read it back before displaying a selection or allowing another change.
      try {
        selected = _decode(await _channel.invokeMethod<String>('getCurrent'));
      } catch (_) {
        selected = null;
        available = false;
      }
      error = '图标切换失败，请重试';
    } finally {
      busy = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
