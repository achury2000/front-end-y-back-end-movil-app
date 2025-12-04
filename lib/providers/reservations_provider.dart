// parte isa
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';
import '../services/reservations_service.dart';
import '../utils/date_utils.dart';
import '../data/mock_reservations.dart';

/// Gestiona las reservas de la aplicación.
///
/// Responsabilidades:
/// - Mantiene la lista de reservas en memoria y la persiste en `SharedPreferences`.
/// - Provee operaciones CRUD (crear, actualizar, eliminar), import/export CSV y audit trail.
/// - Realiza validaciones de negocio (por ejemplo: duplicidad de programación, reglas de eliminación).
///
/// Herencia / Interfaces:
/// - Mezcla `ChangeNotifier` para notificar cambios a los listeners (UI/providers).
///
/// Call-sites típicos:
/// - Instanciada en el árbol de providers y consumida por pantallas como creación/gestión de reservas,
///   pantallas de detalle y formularios (ej. `reservations_create_screen.dart`, `finca_detail_screen.dart`).
class ReservationsProvider with ChangeNotifier {
  static const _prefsKey = 'reservations';

  List<Map<String, dynamic>> _reservations = [];
  final List<Map<String,dynamic>> _audit = [];
  bool _loading = true;
  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 600);

  bool get loading => _loading;

  ReservationsProvider(){
    loadReservations();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get reservations => List.unmodifiable(_reservations);

  Future<void> loadReservations() async {
    _loading = true;
    notifyListeners();
    final prefs = Prefs.instance;
    try {
      final api = await ReservationsService.instance.list();
      if (api.isNotEmpty) {
        _reservations = api;
        await _saveToPrefs();
      } else {
        final raw = prefs.getString(_prefsKey);
        if (raw == null) {
          _reservations = List<Map<String,dynamic>>.from(mockReservations);
          await _saveToPrefs();
        } else {
          try {
            final decoded = jsonDecode(raw) as List<dynamic>;
            _reservations = decoded.map((e) => Map<String,dynamic>.from(e as Map)).toList();
          } catch (e) {
            _reservations = List<Map<String,dynamic>>.from(mockReservations);
          }
        }
      }
    } catch (e) {
      final raw = prefs.getString(_prefsKey);
      if (raw == null) {
        _reservations = List<Map<String,dynamic>>.from(mockReservations);
        await _saveToPrefs();
      } else {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _reservations = decoded.map((e) => Map<String,dynamic>.from(e as Map)).toList();
        } catch (e) {
          _reservations = List<Map<String,dynamic>>.from(mockReservations);
        }
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = Prefs.instance;
    // Use compute to serialize JSON off the UI thread
    final encoded = await compute(_encodeListToJson, _reservations);
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> _saveAuditToPrefs() async {
    final prefs = Prefs.instance;
    final encoded = await compute(_encodeListToJson, _audit);
    await prefs.setString('reservations_audit', encoded);
  }

  Future<String> addReservation(Map<String, dynamic> data) async {
    final id = 'R${DateTime.now().millisecondsSinceEpoch}';
    final entry = Map<String, dynamic>.from(data);
    entry['id'] = id;
    entry['status'] = entry['status'] ?? 'Activa';
    // Validate required fields
    final serviceVal = (entry['service'] ?? '').toString();
    final dateVal = (entry['date'] ?? '').toString();
    final timeVal = (entry['time'] ?? '').toString();
    if (serviceVal.isEmpty || dateVal.isEmpty || timeVal.isEmpty) {
      throw Exception('Faltan campos obligatorios: servicio, fecha y hora son requeridos.');
    }
    // Validate duplicity using helper
    if (existsSameSchedule(service: entry['service']?.toString(), date: entry['date']?.toString(), time: entry['time']?.toString())) {
      throw Exception('Duplicidad: ya existe una programación para este servicio en la misma fecha y hora.');
    }

    // Try to create on API, fallback to local
    try {
      final createdId = await ReservationsService.instance.create(entry);
      if (createdId != null) {
        entry['id'] = createdId;
        _reservations.insert(0, entry);
        _audit.insert(0, {'action':'create_reservation','reservationId': createdId, 'data': entry, 'timestamp': DateTime.now().toIso8601String()});
        await _saveToPrefs();
        notifyListeners();
        return createdId;
      }
    } catch (_) {
      // ignore and fallback
    }
    _reservations.insert(0, entry);
    _audit.insert(0, {'action':'create_reservation','reservationId': id, 'data': entry, 'timestamp': DateTime.now().toIso8601String()});
    notifyListeners();
    _scheduleSave();
    return id;
  }

  Future<void> updateReservation(String id, Map<String, dynamic> data) async {
    final idx = _reservations.indexWhere((r) => r['id'] == id);
    if (idx >= 0) {
      // Prevent status changes via updateReservation - state changes must go through setReservationStatus
      if (data.containsKey('status')) {
        throw Exception('Los cambios de estado deben realizarse desde la pantalla de detalle usando setReservationStatus.');
      }
      // Prepare the merged entry to validate duplicity
      final merged = {..._reservations[idx], ...data};
      // Validate required fields after merge
      final serviceVal = (merged['service'] ?? '').toString();
      final dateVal = (merged['date'] ?? '').toString();
      final timeVal = (merged['time'] ?? '').toString();
      if (serviceVal.isEmpty || dateVal.isEmpty || timeVal.isEmpty) {
        throw Exception('Faltan campos obligatorios: servicio, fecha y hora son requeridos.');
      }
      if (existsSameSchedule(service: merged['service']?.toString(), date: merged['date']?.toString(), time: merged['time']?.toString(), excludeId: id)) {
        throw Exception('Duplicidad: la actualización generaría una programación duplicada.');
      }

      final prev = Map<String,dynamic>.from(_reservations[idx]);
      // Try API update first
      try {
        await ReservationsService.instance.update(id, merged);
        _reservations[idx] = merged;
        _audit.insert(0, {'action':'update_reservation','reservationId': id, 'previous': prev, 'new': merged, 'timestamp': DateTime.now().toIso8601String()});
        await _saveToPrefs();
        notifyListeners();
        return;
      } catch (_) {
        // fallback to local
      }
      _reservations[idx] = merged;
      _audit.insert(0, {'action':'update_reservation','reservationId': id, 'previous': prev, 'new': _reservations[idx], 'timestamp': DateTime.now().toIso8601String()});
      notifyListeners();
      _scheduleSave();
    }
  }

  Future<void> deleteReservation(String id) async {
    final idx = _reservations.indexWhere((r) => r['id'] == id);
    if (idx < 0) return;
    // Business rule: do not delete if activity is currently active (en curso)
    final status = (_reservations[idx]['status'] ?? '').toString().toLowerCase();
    if (status == 'activa' || status == 'en ejecución' || status == 'en ejecucion') {
      throw Exception('No se puede eliminar una actividad en curso.');
    }
    final removed = _reservations.removeAt(idx);
    try {
      await ReservationsService.instance.delete(id);
      _audit.insert(0, {'action':'delete_reservation','reservationId': id, 'data': removed, 'timestamp': DateTime.now().toIso8601String()});
      await _saveToPrefs();
      notifyListeners();
      return;
    } catch (_) {
      // fallback
    }
    _audit.insert(0, {'action':'delete_reservation','reservationId': id, 'data': removed, 'timestamp': DateTime.now().toIso8601String()});
    _scheduleSave();
    notifyListeners();
  }

  Future<void> setReservationStatus(String id, String status, {Map<String,String>? actor, String? reason}) async {
    final idx = _reservations.indexWhere((r) => r['id'] == id);
    if (idx < 0) throw Exception('Registro no encontrado');
    final st = status.toString();
    final prev = _reservations[idx]['status'];
    _reservations[idx]['status'] = st;
    _audit.insert(0, {'action':'set_reservation_status','reservationId': id, 'previous': prev, 'new': st, 'actor': actor ?? {}, 'reason': reason ?? '', 'timestamp': DateTime.now().toIso8601String()});
    await _saveToPrefs();
    await _saveAuditToPrefs();
    notifyListeners();
  }

  Future<void> cancelReservation(String id, {Map<String,String>? actor, String? reason}) async {
    final idx = _reservations.indexWhere((r) => r['id'] == id);
    if (idx >= 0) {
      final prev = _reservations[idx]['status'];
      _reservations[idx]['status'] = 'Cancelada';
      _audit.insert(0, {'action':'cancel_reservation','reservationId': id, 'previous': prev, 'actor': actor ?? {}, 'reason': reason ?? '', 'timestamp': DateTime.now().toIso8601String()});
      await _saveToPrefs();
      await _saveAuditToPrefs();
      notifyListeners();
    }
  }

  // Búsqueda y filtros
  List<Map<String,dynamic>> search({String? query, String? service, String? status, DateTime? from, DateTime? to, String? clientId}){
    Iterable<Map<String,dynamic>> res = _reservations;
    if (clientId != null) res = res.where((r) => (r['clientId'] ?? '') == clientId);
    if (service != null && service.isNotEmpty) res = res.where((r) => (r['service'] ?? '').toString().toLowerCase() == service.toLowerCase());
    if (status != null && status.isNotEmpty) res = res.where((r) => (r['status'] ?? '').toString().toLowerCase() == status.toLowerCase());
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      res = res.where((r) => ((r['service'] ?? '') as String).toLowerCase().contains(q) || ((r['notes'] ?? '') as String).toLowerCase().contains(q));
    }
    if (from != null) res = res.where((r){ try{ final d = parseDateFlexible(r['date']) ; return d==null ? true : !d.isBefore(from);} catch(_){ return true; }});
    if (to != null) res = res.where((r){ try{ final d = parseDateFlexible(r['date']); return d==null ? true : !d.isAfter(to);} catch(_){ return true; }});
    return res.toList();
  }

  // CSV export/import
  String exportCsv(){
    final headers = ['id','service','date','time','clientId','status','notes'];
    final rows = _reservations.map((r) => headers.map((h) => (r[h] ?? '').toString()).join(',')).toList();
    return [headers.join(','), ...rows].join('\n');
  }

  Future<void> importFromCsv(String csv, {bool replace = false, Map<String,String>? actor}) async {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    final headers = lines.first.split(',').map((s)=> s.trim()).toList();
    final entries = <Map<String,dynamic>>[];
    for (var i=1;i<lines.length;i++){
      final cols = lines[i].split(',');
      final Map<String,dynamic> item = {};
      for (var j=0;j<headers.length && j<cols.length;j++){
        item[headers[j]] = cols[j];
      }
      if (!item.containsKey('id') || (item['id'] == null || (item['id'] as String).isEmpty)) item['id'] = 'R${DateTime.now().millisecondsSinceEpoch}${i}';
      entries.add(item);
    }
    if (replace) _reservations = entries;
    else _reservations.insertAll(0, entries);
    _audit.insert(0, {'action':'import_reservations','count': entries.length, 'actor': actor ?? {}, 'timestamp': DateTime.now().toIso8601String()});
    // For import we persist immediately because it's a bulk replace operation
    await _saveToPrefs(); await _saveAuditToPrefs(); notifyListeners();
  }

  /// Replace current reservations with the default mock data and persist.
  Future<void> resetToMock({bool confirm = true}) async {
    // El flag `confirm` se deja por compatibilidad de API; los llamadores pueden invocar sin confirmación
    _reservations = List<Map<String,dynamic>>.from(mockReservations);
    _audit.insert(0, {'action': 'reset_to_mock', 'count': _reservations.length, 'timestamp': DateTime.now().toIso8601String()});
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave(){
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () async {
      try {
        await _saveToPrefs();
        await _saveAuditToPrefs();
      } catch (e) {
        // ignore errors to avoid crashing UI; could log to analytics
      }
    });
  }

  List<Map<String,dynamic>> get audit => List.unmodifiable(_audit);

  Map<String,dynamic>? getById(String id){
    try{ return _reservations.firstWhere((r)=> r['id']==id); } catch(_) { return null; }
  }

  /// Devuelve true si existe una reserva con el mismo servicio+fecha+hora.
  /// Si se provee [excludeId], esa reserva será ignorada (útil al actualizar).
  bool existsSameSchedule({String? service, String? date, String? time, String? excludeId}){
    if (service == null || date == null || time == null) return false;
    final sNorm = service.toLowerCase();
    return _reservations.any((r){
      if (excludeId != null && (r['id'] == excludeId)) return false;
      final rs = (r['service'] ?? '').toString().toLowerCase();
      final rd = (r['date'] ?? '').toString();
      final rt = (r['time'] ?? '').toString();
      return rs == sNorm && rd == date && rt == time;
    });
  }
}

// Top-level helper for compute(): encode a list to JSON string off the UI thread.
String _encodeListToJson(List<dynamic> list) {
  try {
    return jsonEncode(list);
  } catch (e) {
    // Fallback: try to convert each entry to Map and encode
    final safe = list.map((e){
      try { return Map<String,dynamic>.from(e as Map); } catch (_) { return e; }
    }).toList();
    return jsonEncode(safe);
  }
}
