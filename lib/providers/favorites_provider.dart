import 'package:flutter/material.dart';
import '../utils/prefs.dart';

/// Proveedor sencillo para favoritos (persistidos en SharedPreferences).
class FavoritesProvider extends ChangeNotifier {
  static const _prefsKey = 'occitours_favorites_v1';
  Set<String> _ids = {};

  FavoritesProvider() {
    _load();
  }

  List<String> get all => _ids.toList(growable: false);

  bool isFavorite(String id) => _ids.contains(id);

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) _ids.remove(id);
    else _ids.add(id);
    notifyListeners();
    final prefs = Prefs.instance;
    await prefs.setStringList(_prefsKey, _ids.toList());
  }

  Future<void> _load() async {
    final prefs = Prefs.instance;
    final list = prefs.getStringList(_prefsKey) ?? [];
    _ids = list.toSet();
    notifyListeners();
  }
}
