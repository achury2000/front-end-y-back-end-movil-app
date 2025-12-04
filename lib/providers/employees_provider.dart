import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';
import '../utils/json_helpers.dart';
import '../data/mock_employees.dart';

/// Proveedor para gestión de empleados.
///
/// - Carga y persiste una lista simple de empleados en `SharedPreferences`.
/// - Provee operaciones básicas CRUD y notificaciones a la UI.
class EmployeesProvider with ChangeNotifier {
  static const _prefsKey = 'employees';

  List<Map<String, String>> _employees = [];
  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 600);

  EmployeesProvider(){
    loadEmployees();
  }

  List<Map<String, String>> get employees => List.unmodifiable(_employees);

  Future<void> loadEmployees() async {
    final prefs = Prefs.instance;
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      _employees = mockEmployees.map((e) => Map<String,String>.fromEntries(
        (e as Map).entries.map((kv) => MapEntry(kv.key.toString(), kv.value == null ? '' : kv.value.toString()))
      )).toList();
      await _saveToPrefs();
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _employees = decoded.map((e) => Map<String,String>.fromEntries(
          (e as Map).entries.map((kv) => MapEntry(kv.key.toString(), kv.value == null ? '' : kv.value.toString()))
        )).toList();
      } catch (e) {
        _employees = mockEmployees.map((e) => Map<String,String>.fromEntries(
          (e as Map).entries.map((kv) => MapEntry(kv.key.toString(), kv.value == null ? '' : kv.value.toString()))
        )).toList();
      }
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = Prefs.instance;
    final encoded = await compute(encodeToJson, _employees);
    await prefs.setString(_prefsKey, encoded).catchError((_) => false);
  }

  Future<void> addEmployee(Map<String,String> emp) async {
    final id = 'e${DateTime.now().millisecondsSinceEpoch}';
    final newEmp = Map<String,String>.from(emp);
    newEmp['id'] = id;
    _employees.insert(0, newEmp);
    _scheduleSave();
    notifyListeners();
  }

  Future<void> updateEmployee(String id, Map<String,String> data) async {
    final idx = _employees.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      _employees[idx] = {..._employees[idx], ...data};
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e['id'] == id);
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave(){
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () async {
      try {
        await _saveToPrefs();
      } catch(_){}
    });
  }

  @override
  void dispose(){
    _saveTimer?.cancel();
    super.dispose();
  }
}
