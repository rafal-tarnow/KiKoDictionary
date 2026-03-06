import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/token_storage.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart'; // Dodany import

// Provider zwracający skonfigurowany Interceptor
final authInterceptorProvider = Provider<Interceptor>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return AuthInterceptor(storage, ref); // Wstrzykujemy ref
});

class AuthInterceptor extends Interceptor {
  final TokenStorage _storage;
  final Ref _ref; // Ref pozwala nam wezwać logout

  AuthInterceptor(this._storage, this._ref);

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
    // [ZMIANA] Automatyczne wylogowanie przy błędzie 401
    // (Na tym etapie z pominięciem procedury Refresh Token - zrobimy to później)
    if (err.response?.statusCode == 401) {
      // Czyścimy lokalny stan tokenów i usera (wylogowuje z aplikacji)
      _ref.read(authControllerProvider.notifier).logout();
    }
    
    return handler.next(err);
  }
}