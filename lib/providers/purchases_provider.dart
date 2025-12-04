// parte linsaith
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/json_helpers.dart';
import '../utils/prefs.dart';
import '../services/purchases_service.dart';

/// Proveedor para compras (ordenes de compra).
///
/// - Mantiene órdenes de compra, persiste en `SharedPreferences` y registra auditoría.
class PurchasesProvider with ChangeNotifier {
  static const _prefsKey = 'purchases_v1';
  final List<Map<String,dynamic>> _purchases = [];
  final List<Map<String,dynamic>> _audit = [];
  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 600);

  PurchasesProvider(){ _load(); }

  List<Map<String,dynamic>> get purchases => List.unmodifiable(_purchases);
  List<Map<String,dynamic>> get audit => List.unmodifiable(_audit);

  Future<void> _load() async {
    final prefs = Prefs.instance;
    try {
      final api = await PurchasesService.instance.list();
      if (api.isNotEmpty) {
        _purchases.clear();
        _purchases.addAll(api);
        final encoded = await compute(encodeToJson, _purchases);
        await prefs.setString(_prefsKey, encoded);
      } else {
        final raw = prefs.getString(_prefsKey);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw) as List<dynamic>;
            _purchases.clear();
            _purchases.addAll(decoded.map((e) => Map<String,dynamic>.from(e as Map)));
          } catch(_){}
        }
      }
    } catch (_) {
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _purchases.clear();
          _purchases.addAll(decoded.map((e) => Map<String,dynamic>.from(e as Map)));
        } catch(_){}
      }
    }
    final auditRaw = prefs.getString('purchases_audit');
    if (auditRaw != null) {
      try {
        final decoded = jsonDecode(auditRaw) as List<dynamic>;
        _audit.clear();
        _audit.addAll(decoded.map((e) => Map<String,dynamic>.from(e as Map)));
      } catch(_){}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = Prefs.instance;
    final enc = await compute(encodeToJson, _purchases);
    await prefs.setString(_prefsKey, enc).catchError((_) => false);
  }

  Future<void> _saveAudit() async {
    final prefs = Prefs.instance;
    final enc = await compute(encodeToJson, _audit);
    await prefs.setString('purchases_audit', enc).catchError((_) => false);
  }

  Future<String> addPurchase(Map<String,dynamic> p, {Map<String,String>? actor}) async {
    // Try to create purchase on API, fallback to local storage if API fails
    try {
      final apiId = await PurchasesService.instance.create(p);
      final id = apiId ?? 'PO${DateTime.now().millisecondsSinceEpoch}';
      final entry = Map<String,dynamic>.from(p);
      entry['id'] = id;
      entry['status'] = entry['status'] ?? 'Pendiente';
      _purchases.insert(0, entry);
      _audit.insert(0, {'action':'create_purchase','purchaseId': id, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String(), 'data': entry});
      _scheduleSave();
      notifyListeners();
      return id;
    } catch (e) {
      // fallback local
      final id = 'PO${DateTime.now().millisecondsSinceEpoch}';
      final entry = Map<String,dynamic>.from(p);
      entry['id'] = id;
      entry['status'] = entry['status'] ?? 'Pendiente';
      _purchases.insert(0, entry);
      _audit.insert(0, {'action':'create_purchase_offline','purchaseId': id, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String(), 'data': entry});
      _scheduleSave();
      notifyListeners();
      return id;
    }
  }

  Future<void> setPurchaseStatus(String id, String status, {Map<String,String>? actor}) async {
    final idx = _purchases.indexWhere((p) => p['id'] == id);
    if (idx < 0) throw Exception('Compra no encontrada');
    final prev = _purchases[idx]['status'];
    _purchases[idx]['status'] = status;
    _audit.insert(0, {'action':'set_purchase_status','purchaseId': id, 'previous': prev, 'new': status, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String()});
    // Try update on API
    try {
      await PurchasesService.instance.setStatus(id, status);
    } catch (_) {}
    _scheduleSave();
    notifyListeners();
  }

  Future<void> deletePurchase(String id, {Map<String,String>? actor}) async {
    final idx = _purchases.indexWhere((p) => p['id'] == id);
    if (idx < 0) return;
    final removed = _purchases.removeAt(idx);
    _audit.insert(0, {'action':'delete_purchase','purchaseId': id, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String(), 'data': removed});
    try {
      await PurchasesService.instance.delete(id);
    } catch (_) {}
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave(){
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () async {
      try {
        await _save();
        await _saveAudit();
      } catch (e) {
        // ignore
      }
    });
  }

  @override
  void dispose(){
    _saveTimer?.cancel();
    super.dispose();
  }
}
