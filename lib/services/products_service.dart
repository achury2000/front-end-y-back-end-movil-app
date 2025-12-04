import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class ProductsService {
  static final ProductsService instance = ProductsService._internal();
  final Dio _dio = ApiService.instance.dio;

  ProductsService._internal();

  /// List products. Supports optional query params (page, q, category)
  Future<List<Product>> list({int? page, String? q, String? category}) async {
    final params = <String, dynamic>{};
    if (page != null) params['page'] = page;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (category != null && category.isNotEmpty) params['category'] = category;
    final resp = await _dio.get('/products', queryParameters: params);
    final data = resp.data;
    if (data is List) {
      return data.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List).map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<Product?> getById(String id) async {
    final resp = await _dio.get('/products/$id');
    final data = resp.data;
    if (data is Map) return Product.fromJson(Map<String, dynamic>.from(data));
    return null;
  }
}
