import 'package:dio/dio.dart';
import '../services/api_service.dart';

class PurchasesService {
  static final PurchasesService instance = PurchasesService._internal();
  final Dio _dio = ApiService.instance.dio;
  PurchasesService._internal();

  Future<List<Map<String,dynamic>>> list() async {
    final resp = await _dio.get('/orders');
    final data = resp.data;
    if (data is List) return data.map((e) => Map<String,dynamic>.from(e)).toList();
    if (data is Map && data['items'] is List) return (data['items'] as List).map((e) => Map<String,dynamic>.from(e)).toList();
    return [];
  }

  Future<String?> create(Map<String,dynamic> payload) async {
    final resp = await _dio.post('/orders', data: payload);
    return resp.data?['order_id']?.toString() ?? resp.data?['id']?.toString();
  }

  Future<void> setStatus(String id, String status) async {
    await _dio.put('/orders/$id/status', data: {'status': status});
  }

  Future<void> delete(String id) async {
    await _dio.delete('/orders/$id');
  }
}
