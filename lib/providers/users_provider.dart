// parte linsaith
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_users.dart';
import '../models/user.dart';

class UsersProvider with ChangeNotifier {
  static const _prefsKey = 'users_v1';

  List<User> _users = [];
  final List<Map<String, dynamic>> _audit = [];

  List<User> get users => List.unmodifiable(_users);

  UsersProvider(){
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      _users = List<User>.from(mockUsers);
      await _save();
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _users = decoded.map((m) => User(
          id: m['id'] as String,
          name: m['name'] as String,
          email: m['email'] as String,
          role: m['role'] as String? ?? 'customer',
          phone: m['phone'] as String?,
          address: m['address'] as String?,
          active: m['active'] as bool? ?? true,
        )).toList();
      } catch (e) {
        _users = List<User>.from(mockUsers);
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _users.map((u) => {
      'id': u.id,
      'name': u.name,
      'email': u.email,
      'role': u.role,
      'phone': u.phone,
      'address': u.address,
      'active': u.active,
    }).toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> _saveAudit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users_audit', jsonEncode(_audit));
  }

  List<Map<String, dynamic>> get audit => List.unmodifiable(_audit);

  bool emailExists(String email, {String? excludeId}) {
    final e = email.toLowerCase();
    return _users.any((u) => u.email.toLowerCase() == e && (excludeId == null || u.id != excludeId));
  }

  Future<void> addUser(Map<String, dynamic> data, {Map<String, String>? actor}) async {
    final id = 'u${DateTime.now().millisecondsSinceEpoch}';
    final user = User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      phone: data['phone'],
      address: data['address'],
    );
    _users.insert(0, user);
    _audit.insert(0, {
      'action': 'create_user',
      'userId': id,
      'actor': actor ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'name': user.name,
        'email': user.email,
        'role': user.role
      }
    });
    await _save();
    await _saveAudit();
    notifyListeners();
  }

  Future<void> updateUser(String id, Map<String, dynamic> data, {Map<String, String>? actor}) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      final u = _users[idx];
      u.name = data['name'] ?? u.name;
      u.email = data['email'] ?? u.email;
      u.role = data['role'] ?? u.role;
      u.phone = data['phone'] ?? u.phone;
      u.address = data['address'] ?? u.address;
      if (data.containsKey('active')) {
        u.active = data['active'] as bool;
      }
      _audit.insert(0, {
        'action': 'update_user',
        'userId': id,
        'actor': actor ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'changes': data
      });
      await _save();
      await _saveAudit();
      notifyListeners();
    }
  }

  Future<void> toggleActiveWithAudit(String id, {Map<String, String>? actor}) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      _users[idx].active = !_users[idx].active;
      _audit.insert(0, {
        'action': 'toggle_active_user',
        'userId': id,
        'newValue': _users[idx].active,
        'actor': actor ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _save();
      await _saveAudit();
      notifyListeners();
    }
  }

  Future<void> deleteUserWithAudit(String id, {Map<String, String>? actor}) async {
    _users.removeWhere((u) => u.id == id);
    _audit.insert(0, {
      'action': 'delete_user',
      'userId': id,
      'actor': actor ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _save();
    await _saveAudit();
    notifyListeners();
  }

  Future<void> updateRole(String id, String role) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      _users[idx].role = role;
      await _save();
      // also persist a per-user key to help AuthProvider pick up changes
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole_' + id, role);
      notifyListeners();
    }
  }
}
