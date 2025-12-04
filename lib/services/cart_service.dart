import 'package:dio/dio.dart';
import '../services/api_service.dart';

class CartService {
  static final CartService instance = CartService._internal();
  final Dio _dio = ApiService.instance.dio;
  CartService._internal();

  Future<List<dynamic>> getCart() async {
    final resp = await _dio.get('/cart');
    final data = resp.data;
    List items = [];
    if (data is List) items = data;
    else if (data is Map && data['items'] is List) items = data['items'];
    // Normalize to frontend shape: { productId, quantity, variant }
    return items.map((e) {
      final servicioId = e['servicio_id'] ?? e['service_id'] ?? e['productId'] ?? e['id'];
      final cantidad = e['cantidad'] ?? e['quantity'] ?? e['qty'] ?? 1;
      return {'productId': servicioId?.toString(), 'quantity': cantidad, 'variant': e['variant']};
    }).toList();
  }

  Future<void> addToCart(Map<String,dynamic> payload) async {
    final servicio = payload['productId'] ?? payload['servicio_id'] ?? payload['id'];
    final cantidad = payload['quantity'] ?? payload['cantidad'] ?? 1;
    final precio = payload['price'] ?? payload['precio_unitario'];
    await _dio.post('/cart/items', data: {'servicio_id': servicio, 'cantidad': cantidad, 'precio_unitario': precio});
  }

  Future<void> updateItem(String itemId, Map<String,dynamic> payload) async {
    await _dio.put('/cart/items/$itemId', data: {
      'cantidad': payload['quantity'] ?? payload['cantidad'],
      'precio_unitario': payload['price'] ?? payload['precio_unitario']
    });
  }

  Future<void> clear() async {
    // Backend doesn't expose a single delete endpoint for the whole cart; delete items individually
    final resp = await _dio.get('/cart');
    final data = resp.data;
    List items = [];
    if (data is List) items = data;
    else if (data is Map && data['items'] is List) items = data['items'];
    for (final it in items) {
      final id = it['id'] ?? it['item_id'];
      if (id != null) {
        await _dio.delete('/cart/items/$id');
      }
    }
  }
}
