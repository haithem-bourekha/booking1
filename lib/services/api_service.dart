import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final response = await _dio.post(
                '$baseUrl/auth/refresh/',
                data: {'refresh': refreshToken},
              );
              final newAccessToken = response.data['access'];
              await _storage.write(key: 'access_token', value: newAccessToken);
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              return handler.resolve(await _dio.fetch(e.requestOptions));
            } catch (_) {
              await _storage.deleteAll();
              return handler.next(e);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) {
    return _dio.get('$baseUrl$endpoint', queryParameters: queryParameters);
  }

  Future<Response> post(String endpoint, {dynamic data}) {
    return _dio.post('$baseUrl$endpoint', data: data);
  }

  Future<Response> put(String endpoint, {dynamic data}) {
    return _dio.put('$baseUrl$endpoint', data: data);
  }

  Future<Response> patch(String endpoint, {dynamic data}) {
    return _dio.patch('$baseUrl$endpoint', data: data);
  }

  Future<Response> delete(String endpoint) {
    return _dio.delete('$baseUrl$endpoint');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}