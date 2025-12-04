import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();

  final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService._internal() : dio = Dio(BaseOptions(baseUrl: API_BASE_URL, connectTimeout: API_TIMEOUT_SECONDS * 1000)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioError e, handler) async {
        // Try refresh once on 401
        final response = e.response;
        if (response != null && response.statusCode == 401) {
          try {
            final refreshed = await AuthService.instance.refresh();
            if (refreshed != null && refreshed.isNotEmpty) {
              // set header and retry
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer $refreshed';
              final cloneReq = await dio.request(opts.path,
                  options: Options(method: opts.method, headers: opts.headers),
                  data: opts.data,
                  queryParameters: opts.queryParameters);
              return handler.resolve(cloneReq);
            }
          } catch (_) {
            // ignore and pass original error
          }
        }
        return handler.next(e);
      },
    ));
  }
}
