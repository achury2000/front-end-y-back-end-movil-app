import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/prefs.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../data/mock_users.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider(){
    _loadFromPrefs();
  }
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Try real API login first
      try {
        final result = await AuthService.instance.login(email, password);
        final user = result['user'];
        final access = result['access_token'] as String?;
        if (access != null) _token = access;
        if (user is Map<String, dynamic>) {
          _user = User.fromJson(user);
        }
        // persist lightweight info in Prefs for compatibility with existing code
        final prefs = Prefs.instance;
        if (_token != null) await prefs.setString('token', _token!);
        if (_user != null) await prefs.setString('userId', _user!.id);
      } catch (apiErr) {
        // fallback to local mock if API is not available
        await Future.delayed(Duration(seconds: 1));
        final found = mockUsers.firstWhere((u) => u.email == email, orElse: () => throw 'User not found');
        _user = found;
        _token = 'mock-token-${found.id}';
        final prefs = Prefs.instance;
        await prefs.setString('token', _token!);
        await prefs.setString('userId', found.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = Prefs.instance;
    await prefs.remove('token');
    await prefs.remove('userId');
    await AuthService.instance.logout();
    notifyListeners();
  }

  Future<void> verifySession() async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 600));
    final prefs = Prefs.instance;
    final storedToken = prefs.getString('token');
    final userId = prefs.getString('userId');
    if (storedToken != null && userId != null) {
      try {
        _user = mockUsers.firstWhere((u) => u.id == userId);
        _token = storedToken;
        // refresh persisted role if admin changed it via users provider
        final roleOverride = prefs.getString('userRole_' + userId);
        if (roleOverride != null) {
          _user = User(id: _user!.id, name: _user!.name, email: _user!.email, role: roleOverride, phone: _user!.phone, address: _user!.address);
        }
      } catch (_) {}
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = Prefs.instance;
    final storedToken = prefs.getString('token');
    final userId = prefs.getString('userId');
    if (storedToken != null && userId != null) {
      try {
        _user = mockUsers.firstWhere((u) => u.id == userId);
        final roleOverride = prefs.getString('userRole_' + userId);
        if (roleOverride != null) {
          _user = User(id: _user!.id, name: _user!.name, email: _user!.email, role: roleOverride, phone: _user!.phone, address: _user!.address);
        }
        _token = storedToken;
        notifyListeners();
      } catch (_) {}
    }
  }

  bool hasAnyRole(List<String> roles){
    final r = (_user?.role ?? '').toLowerCase();
    return roles.map((e)=> e.toLowerCase()).contains(r);
  }
}
