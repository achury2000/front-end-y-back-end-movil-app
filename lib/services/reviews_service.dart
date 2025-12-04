import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/review.dart';

class ReviewsService {
  static final ReviewsService instance = ReviewsService._internal();
  final Dio _dio = ApiService.instance.dio;
  ReviewsService._internal();

  Future<List<Review>> list({Map<String,dynamic>? params}) async {
    final resp = await _dio.get('/reviews', queryParameters: params);
    final data = resp.data;
    if (data is List) return data.map((e) => Review.fromMap(Map<String,dynamic>.from(e))).toList();
    if (data is Map && data['items'] is List) return (data['items'] as List).map((e) => Review.fromMap(Map<String,dynamic>.from(e))).toList();
    return [];
  }

  Future<String?> create(Map<String,dynamic> payload) async {
    final resp = await _dio.post('/reviews', data: payload);
    return resp.data?['id']?.toString();
  }
}
