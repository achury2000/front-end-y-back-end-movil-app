// parte juanjo
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';
import '../utils/json_helpers.dart';

class SalesProvider with ChangeNotifier {
  static const _prefsKey = 'sales_v1';
  final List<Map<String,dynamic>> _sales = [];
  final List<Map<String,dynamic>> _audit = [];

  SalesProvider(){ _load(); }

  List<Map<String,dynamic>> get sales => List.unmodifiable(_sales);
  List<Map<String,dynamic>> get audit => List.unmodifiable(_audit);

  Future<void> _load() async {
    final prefs = Prefs.instance;
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _sales.clear();
        _sales.addAll(decoded.map((e) => Map<String,dynamic>.from(e as Map)));
      } catch (_){ }
    }
    final ar = prefs.getString('sales_audit');
    if (ar != null) {
      try {
        final d = jsonDecode(ar) as List<dynamic>;
        _audit.clear();
        _audit.addAll(d.map((e) => Map<String,dynamic>.from(e as Map)));
      } catch (_){ }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    // Serialize off the UI thread and persist in background.
    final encoded = await compute(encodeToJson, _sales);
    Future(() async {
      try {
        final prefs = Prefs.instance;
        await prefs.setString(_prefsKey, encoded);
      } catch (_) {}
    });
  }

  Future<void> _saveAudit() async {
    final encoded = await compute(encodeToJson, _audit);
    Future(() async {
      try {
        final prefs = Prefs.instance;
        await prefs.setString('sales_audit', encoded);
      } catch (_) {}
    });
  }

  Future<String> addSale(Map<String,dynamic> s, {Map<String,String>? actor}) async {
    final id = 'S${DateTime.now().millisecondsSinceEpoch}';
    final entry = Map<String,dynamic>.from(s);
    entry['id'] = id;
    entry['createdAt'] = entry['createdAt'] ?? DateTime.now().toIso8601String();
    entry['status'] = entry['status'] ?? 'Pendiente';
    _sales.insert(0, entry);
    _audit.insert(0, {'action':'create_sale','saleId': id, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String(), 'data': entry});
    // Persist in background to avoid blocking UI
    _save().catchError((_){});
    _saveAudit().catchError((_){});
    notifyListeners();
    return id;
  }

  Map<String,dynamic> getById(String id){
    try { return _sales.firstWhere((s) => s['id'] == id); } catch (_) { return {}; }
  }

  List<Map<String,dynamic>> salesForClient(String clientId){
    return _sales.where((s)=> (s['clientId'] ?? '') == clientId).toList();
  }

  Future<void> updateSale(String id, Map<String,dynamic> changes, {Map<String,String>? actor}) async {
    final idx = _sales.indexWhere((s)=> s['id'] == id);
    if (idx < 0) throw Exception('Venta no encontrada');
    final prev = Map<String,dynamic>.from(_sales[idx]);
    _sales[idx] = {..._sales[idx], ...changes};
    _audit.insert(0, {'action':'update_sale','saleId': id, 'previous': prev, 'new': _sales[idx], 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String()});
    _save().catchError((_){});
    _saveAudit().catchError((_){});
    notifyListeners();
  }

  Future<void> deleteSale(String id, {Map<String,String>? actor}) async {
    final idx = _sales.indexWhere((s)=> s['id'] == id);
    if (idx < 0) return;
    final removed = _sales.removeAt(idx);
    _audit.insert(0, {'action':'delete_sale','saleId': id, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String(), 'data': removed});
    _save().catchError((_){});
    _saveAudit().catchError((_){});
    notifyListeners();
  }

  // simple search with filters
  List<Map<String,dynamic>> search({String? clientId, String? serviceType, String? query, DateTime? from, DateTime? to}){
    Iterable<Map<String,dynamic>> res = _sales;
    if (clientId != null) res = res.where((s)=> (s['clientId'] ?? '') == clientId);
    if (serviceType != null) res = res.where((s)=> (s['serviceType'] ?? '').toString().toLowerCase() == serviceType.toLowerCase());
    if (query != null && query.isNotEmpty) res = res.where((s)=> (s['serviceName'] ?? '').toString().toLowerCase().contains(query.toLowerCase()));
    if (from != null) res = res.where((s){ try{ final d = DateTime.parse(s['createdAt']); return !d.isBefore(from);} catch(_){ return true; }});
    if (to != null) res = res.where((s){ try{ final d = DateTime.parse(s['createdAt']); return !d.isAfter(to);} catch(_){ return true; }});
    return res.toList();
  }
}
