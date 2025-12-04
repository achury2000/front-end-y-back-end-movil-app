// parte linsaith
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';
import '../utils/json_helpers.dart';
import '../data/mock_users.dart';
import '../models/user.dart';
import '../services/users_service.dart';

class UsersProvider with ChangeNotifier {
  static const _prefsKey = 'users_v1';

  List<User> _users = [];
  final List<Map<String, dynamic>> _audit = [];

  List<User> get users => List.unmodifiable(_users);

  UsersProvider(){
    _load();
  }

  Future<void> _load() async {
    final prefs = Prefs.instance;
    try {
      final api = await UsersService.instance.list();
      if (api.isNotEmpty) {
        _users = api.map((m) => User.fromJson(m)).toList();
        await _save();
      } else {
        final raw = prefs.getString(_prefsKey);
        if (raw == null) {
          _users = List<User>.from(mockUsers);
          await _save();
        } else {
          try {
            final decoded = jsonDecode(raw) as List<dynamic>;
            _users = decoded.map((m) => User.fromJson(Map<String,dynamic>.from(m as Map))).toList();
          } catch (e) {
            _users = List<User>.from(mockUsers);
          }
        }
      }
    } catch (_) {
      final raw = prefs.getString(_prefsKey);
      if (raw == null) {
        _users = List<User>.from(mockUsers);
        await _save();
      } else {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _users = decoded.map((m) => User.fromJson(Map<String,dynamic>.from(m as Map))).toList();
        } catch (e) {
          _users = List<User>.from(mockUsers);
        }
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final data = _users.map((u) => {
      'id': u.id,
      'name': u.name,
      'email': u.email,
      'role': u.role,
      'phone': u.phone,
      'address': u.address,
      'active': u.active,
    }).toList();
    final encoded = await compute(encodeToJson, data);
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
        await prefs.setString('users_audit', encoded);
      } catch (_) {}
    });
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
    _save().catchError((_){});
    _saveAudit().catchError((_){});
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
      _save().catchError((_){});
      _saveAudit().catchError((_){});
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
      _save().catchError((_){});
      _saveAudit().catchError((_){});
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
    _save().catchError((_){});
    _saveAudit().catchError((_){});
    notifyListeners();
  }

  Future<void> updateRole(String id, String role) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      _users[idx].role = role;
      _save().catchError((_){});
      // also persist a per-user key to help AuthProvider pick up changes
      try {
        final prefs = Prefs.instance;
        await prefs.setString('userRole_' + id, role);
      } catch (_) {}
      notifyListeners();
    }
  }
}
