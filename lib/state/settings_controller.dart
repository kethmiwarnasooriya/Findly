import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where user preferences are stored. Only non-sensitive display settings
/// belong here; nothing secret is ever written through this interface.
abstract interface class SettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// User-adjustable app settings.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  final SettingsStore _store;
  static const _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Loads saved settings. Falls back to defaults if storage is unavailable.
  Future<void> load() async {
    try {
      final saved = await _store.read(_themeKey);
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _store.write(_themeKey, mode.name);
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}
