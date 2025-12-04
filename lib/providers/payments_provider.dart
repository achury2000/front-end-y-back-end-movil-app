// parte linsaith
// parte juanjo
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/json_helpers.dart';
import '../utils/prefs.dart';
import '../models/payment.dart';

/// Proveedor para pagos.
///
/// - Administra pagos registrados, persistencia y un log de auditoría.
class PaymentsProvider with ChangeNotifier {
  static const _prefsKey = 'payments_v1';
  static const _auditKey = 'payments_audit_v1';
  List<Payment> _items = [];
  final List<Map<String,dynamic>> _audit = [];
  bool _loading = true;
  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 600);

  PaymentsProvider(){ _load(); }

  List<Payment> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  List<Map<String,dynamic>> get audit => List.unmodifiable(_audit);

  Future<void> _load() async {
    _loading = true; notifyListeners();
    final prefs = Prefs.instance;
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try { _items = Payment.decodeList(raw); } catch (_) { _items = []; }
    } else {
      _items = [];
      await _save();
    }
    final auditRaw = prefs.getString(_auditKey);
    if (auditRaw != null && auditRaw.isNotEmpty) {
      try { final decoded = jsonDecode(auditRaw) as List<dynamic>; _audit.clear(); _audit.addAll(decoded.map((e)=> Map<String,dynamic>.from(e as Map))); } catch (_) {}
    }
    _loading = false; notifyListeners();
  }

  Future<void> _save() async {
    final prefs = Prefs.instance;
    final encItems = await compute(encodeToJson, _items.map((e) => e.toMap()).toList());
    await prefs.setString(_prefsKey, encItems).catchError((_) => false);
    final encAudit = await compute(encodeToJson, _audit);
    await prefs.setString(_auditKey, encAudit).catchError((_) => false);
  }

  Future<void> addPayment(Payment p, {Map<String,String>? actor}) async {
    if (p.amount <= 0) throw Exception('El monto debe ser mayor a 0');
    _items.insert(0, p);
    _audit.insert(0, {'action':'create_payment','id': p.id, 'data': p.toMap(), 'actor': actor, 'timestamp': DateTime.now().toIso8601String()});
    _scheduleSave(); notifyListeners();
  }

  Future<void> updatePayment(String id, Map<String,dynamic> changes, {Map<String,String>? actor}) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) throw Exception('Pago no encontrado');
    final before = _items[idx].toMap();
    final merged = {...before, ...changes};
    _items[idx] = Payment.fromMap(merged);
    _audit.insert(0, {'action':'update_payment','id': id, 'before': before, 'after': _items[idx].toMap(), 'actor': actor, 'timestamp': DateTime.now().toIso8601String()});
    _scheduleSave(); notifyListeners();
  }

  Future<void> deletePayment(String id, {Map<String,String>? actor}) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final removed = _items.removeAt(idx);
    _audit.insert(0, {'action':'delete_payment','id': id, 'data': removed.toMap(), 'actor': actor, 'timestamp': DateTime.now().toIso8601String()});
    _scheduleSave(); notifyListeners();
  }

  Payment? findById(String id){ try { return _items.firstWhere((e)=> e.id == id);} catch(_) { return null; } }

  String exportCsv(){
    final headers = ['id','reservationId','amount','currency','method','status','timestamp'];
    final rows = _items.map((p) => headers.map((h) => (p.toMap()[h] ?? '').toString()).join(',')).toList();
    return [headers.join(','), ...rows].join('\n');
  }

  Future<void> importFromCsv(String csv, {bool replace = false, Map<String,String>? actor}) async {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    final headers = lines.first.split(',').map((s)=> s.trim()).toList();
    final entries = <Payment>[];
    for (var i=1;i<lines.length;i++){
      final cols = lines[i].split(',');
      final map = <String,dynamic>{};
      for (var j=0;j<headers.length && j<cols.length;j++) map[headers[j]] = cols[j];
      if (map['id'] == null || (map['id'] as String).isEmpty) map['id'] = 'P${DateTime.now().millisecondsSinceEpoch}${i}';
      entries.add(Payment.fromMap(map));
    }
    if (replace) _items = entries; else _items.insertAll(0, entries);
    _audit.insert(0, {'action':'import_payments','count': entries.length, 'actor': actor, 'timestamp': DateTime.now().toIso8601String()});
    _scheduleSave(); notifyListeners();
  }

  void _scheduleSave(){
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () async {
      try {
        await _save();
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

