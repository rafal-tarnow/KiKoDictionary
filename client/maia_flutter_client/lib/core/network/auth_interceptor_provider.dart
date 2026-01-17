import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/token_storage.dart';

// Provider zwracający skonfigurowany Interceptor
final authInterceptorProvider = Provider<Interceptor>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return AuthInterceptor(storage);
});

class AuthInterceptor extends Interceptor {
  final TokenStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Pobierz token
    final token = await _storage.getToken();

    // Dodaj nagłówek jeśli token istnieje
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Tu w przyszłości dodasz logikę odświeżania tokena (Refresh Token)
    // jeśli err.response?.statusCode == 401
    return handler.next(err);
  }
}