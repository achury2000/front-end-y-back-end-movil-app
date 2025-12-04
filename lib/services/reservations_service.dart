import 'package:dio/dio.dart';
import '../services/api_service.dart';

class ReservationsService {
  static final ReservationsService instance = ReservationsService._internal();
  final Dio _dio = ApiService.instance.dio;

  ReservationsService._internal();

  Future<List<Map<String, dynamic>>> list({Map<String,dynamic>? params}) async {
    final resp = await _dio.get('/reservations', queryParameters: params);
    final data = resp.data;
    if (data is List) return data.map((e) => Map<String,dynamic>.from(e)).toList();
    if (data is Map && data['items'] is List) return (data['items'] as List).map((e) => Map<String,dynamic>.from(e)).toList();
    return [];
  }

  Future<Map<String,dynamic>?> getById(String id) async {
    final resp = await _dio.get('/reservations/$id');
    if (resp.data is Map) return Map<String,dynamic>.from(resp.data);
    return null;
  }

  Future<String?> create(Map<String,dynamic> payload) async {
    final resp = await _dio.post('/reservations', data: payload);
    final data = resp.data as Map<String,dynamic>;
    return data['id']?.toString();
  }

  Future<void> update(String id, Map<String,dynamic> payload) async {
    await _dio.put('/reservations/$id', data: payload);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/reservations/$id');
  }
}
