import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'settings.dart';
import 'settings_store.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._store);
  final SettingsStore _store;
  AppSettings _settings = AppSettings.defaults();
  bool _saveFailed = false, _disposed = false;
  int _revision = 0, _savedRevision = 0;
  Timer? _debounce;
  Future<void> _queue = Future.value();
  AppSettings get settings => _settings;
  bool get saveFailed => _saveFailed;

  Future<void> load() async {
    try {
      final raw = await _store.read();
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> && !_disposed) {
          _settings = AppSettings.fromJson(decoded);
        }
      }
    } catch (_) {
      // Missing or damaged local data must not prevent opening the player.
    }
    if (!_disposed) notifyListeners();
  }

  void update(AppSettings next, {bool commit = false}) {
    if (_disposed) return;
    _settings = next;
    _revision++;
    notifyListeners();
    _debounce?.cancel();
    if (commit) {
      unawaited(flush());
    } else {
      _debounce = Timer(
        const Duration(milliseconds: 200),
        () => unawaited(flush()),
      );
    }
  }

  Future<void> flush() {
    _debounce?.cancel();
    if (_disposed) return Future.value();
    // Queue requests even during an active write. A retry after an earlier
    // failure is preserved, and a stale write can never finish after a new one.
    _queue = _queue.then((_) async {
      while (!_disposed && _savedRevision < _revision) {
        final revision = _revision;
        final json = jsonEncode(_settings.toJson());
        try {
          await _store.write(json);
          _savedRevision = revision;
          _setSaveFailed(false);
        } catch (_) {
          _setSaveFailed(true);
          return;
        }
      }
    });
    return _queue;
  }

  void _setSaveFailed(bool failed) {
    if (_disposed || _saveFailed == failed) return;
    _saveFailed = failed;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
