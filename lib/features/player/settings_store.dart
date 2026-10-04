import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsStore {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesSettingsStore implements SettingsStore {
  static const _key = 'hypnoloop.settings.v1';
  final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(_key);
  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}
