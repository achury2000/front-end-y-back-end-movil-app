import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();

  final Dio _dio = ApiService.instance.dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final data = resp.data as Map<String, dynamic>;
    // Expecting { access_token, refresh_token?, user }
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access != null) {
      await _storage.write(key: 'access_token', value: access);
    }
    if (refresh != null) {
      await _storage.write(key: 'refresh_token', value: refresh);
    }
    return data;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getAccessToken() async => await _storage.read(key: 'access_token');

  Future<Map<String, dynamic>?> register(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/auth/register', data: payload);
    final data = resp.data as Map<String, dynamic>;
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access != null) await _storage.write(key: 'access_token', value: access);
    if (refresh != null) await _storage.write(key: 'refresh_token', value: refresh);
    return data;
  }

  Future<String?> refresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;
    final resp = await _dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
    final data = resp.data as Map<String, dynamic>;
    final access = data['access_token'] as String?;
    final refreshNew = data['refresh_token'] as String?;
    if (access != null) await _storage.write(key: 'access_token', value: access);
    if (refreshNew != null) await _storage.write(key: 'refresh_token', value: refreshNew);
    return access;
  }
}
