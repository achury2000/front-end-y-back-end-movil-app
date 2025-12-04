import 'package:shared_preferences/shared_preferences.dart';

/// Simple singleton accessor for SharedPreferences.
///
/// Call `Prefs.init()` once during app startup (before heavy UI flows)
/// to ensure the native plugin is initialized and the instance cached.
class Prefs {
  static SharedPreferences? _instance;

  /// Initialize and cache the SharedPreferences instance.
  static Future<void> init() async {
    if (_instance != null) return;
    _instance = await SharedPreferences.getInstance();
  }

  /// Returns the cached instance. Ensure `init()` was called earlier.
  static SharedPreferences get instance {
    if (_instance == null) throw StateError('Prefs not initialized. Call Prefs.init() before using.');
    return _instance!;
  }
}
