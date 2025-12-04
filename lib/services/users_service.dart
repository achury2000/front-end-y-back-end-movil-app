import 'package:dio/dio.dart';
import '../services/api_service.dart';

class UsersService {
  static final UsersService instance = UsersService._internal();
  final Dio _dio = ApiService.instance.dio;
  UsersService._internal();

  Future<Map<String,dynamic>?> me() async {
    final resp = await _dio.get('/users/me');
    if (resp.data is Map) return Map<String,dynamic>.from(resp.data);
    return null;
  }

  Future<List<Map<String,dynamic>>> list() async {
    final resp = await _dio.get('/users');
    final data = resp.data;
    if (data is List) return data.map((e) => Map<String,dynamic>.from(e)).toList();
    if (data is Map && data['items'] is List) return (data['items'] as List).map((e) => Map<String,dynamic>.from(e)).toList();
    return [];
  }

  Future<void> update(String id, Map<String,dynamic> payload) async {
    await _dio.put('/users/$id', data: payload);
  }
}
