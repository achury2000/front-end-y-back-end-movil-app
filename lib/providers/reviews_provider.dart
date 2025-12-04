// parte linsaith
// parte juanjo
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../utils/prefs.dart';
import '../utils/json_helpers.dart';
import '../services/reviews_service.dart';

/// Proveedor para opiniones/reseñas (reviews).
///
/// Responsabilidades:
/// - Almacenar y recuperar `Review` desde `SharedPreferences`.
/// - Proveer operaciones CRUD y búsqueda filtrada por objetivo o puntuación.
///
/// Herencia / Interfaces:
/// - Mezcla `ChangeNotifier` para notificar a la UI cuando cambian las reseñas.
///
/// Call-sites típicos:
/// - Utilizado por pantallas que muestran o permiten añadir reseñas para fincas, rutas o servicios.
class ReviewsProvider with ChangeNotifier {
  static const _prefsKey = 'reviews_v1';
  List<Review> _items = [];
  bool _loading = true;

  ReviewsProvider(){ _load(); }

  bool get loading => _loading;
  List<Review> get items => List.unmodifiable(_items);

  Future<void> _load() async {
    _loading = true; notifyListeners();
    final prefs = Prefs.instance;
    try {
      final api = await ReviewsService.instance.list();
      if (api.isNotEmpty) {
        _items = api;
        await _save();
      } else {
        final raw = prefs.getString(_prefsKey);
        if (raw != null && raw.isNotEmpty) {
          try { _items = Review.decodeList(raw); } catch(_) { _items = []; }
        } else {
          _items = [];
          await _save();
        }
      }
    } catch (_) {
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        try { _items = Review.decodeList(raw); } catch(_) { _items = []; }
      } else {
        _items = [];
        await _save();
      }
    }
    _loading = false; notifyListeners();
  }

  Future<void> _save() async {
    final prefs = Prefs.instance;
    final encoded = await compute(encodeToJson, _items.map((e)=> e.toMap()).toList());
    await prefs.setString(_prefsKey, encoded).catchError((_) => false);
  }

  Future<String> addReview(Review r) async {
    try {
      final id = await ReviewsService.instance.create(r.toMap());
      if (id != null) {
        final created = Review.fromMap({...r.toMap(), 'id': id});
        _items.insert(0, created);
        await _save(); notifyListeners();
        return created.id;
      }
    } catch (_) {}
    _items.insert(0, r);
    await _save(); notifyListeners();
    return r.id;
  }

  Future<void> updateReview(String id, Review updated) async {
    final idx = _items.indexWhere((e)=> e.id == id);
    if (idx == -1) throw Exception('Review no encontrada');
    _items[idx] = updated;
    await _save(); notifyListeners();
  }

  Future<void> deleteReview(String id) async {
    final idx = _items.indexWhere((e)=> e.id == id);
    if (idx == -1) return;
    _items.removeAt(idx);
    await _save(); notifyListeners();
  }

  Review? findById(String id){ try{ return _items.firstWhere((e)=> e.id == id);} catch(_) { return null; } }

  List<Review> search({String? targetId, String? targetType, int? minRating}){
    Iterable<Review> res = _items;
    if (targetId != null && targetId.isNotEmpty) res = res.where((r)=> r.targetId == targetId);
    if (targetType != null && targetType.isNotEmpty) res = res.where((r)=> r.targetType == targetType);
    if (minRating != null) res = res.where((r)=> r.rating >= minRating);
    return res.toList();
  }
}
