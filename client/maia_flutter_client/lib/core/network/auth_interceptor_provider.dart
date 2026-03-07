import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/token_storage.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/data/models/auth_token.dart';
import '../config/api_config.dart';

final authInterceptorProvider = Provider<Interceptor>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return AuthInterceptor(storage, ref);
});

// ZMIANA: Używamy QueuedInterceptor. Blokuje on inne zapytania, 
// dopóki odświeżanie tokena się nie zakończy.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _storage;
  final Ref _ref;

  // Czysta instancja Dio dedykowana TYLKO do odświeżania tokenów.
  // Nie ma podpiętych interceptorów, więc omija nieskończone pętle.
  final Dio _refreshDio;

  AuthInterceptor(this._storage, this._ref)
      : _refreshDio = Dio(BaseOptions(
          baseUrl: ApiConfig.authBaseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ));

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Pobierz obecny token z pamięci urządzenia
    final token = await _storage.getToken();

    // 2. Jeśli istnieje, dodaj go do nagłówka
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Sprawdzamy czy błąd to 401 Unauthorized (Wygasły token)
    if (err.response?.statusCode == 401) {
      
      // ZABEZPIECZENIE: Jeśli to zapytanie było już ponawiane i znowu dostało 401,
      // oznacza to krytyczny błąd autoryzacji. Wylogowujemy natychmiast.
      if (err.requestOptions.extra['isRetry'] == true) {
        _forceLogout();
        return handler.next(err);
      }

      final token = await _storage.getToken();

      // Próbujemy uratować sesję za pomocą Refresh Tokena
      if (token != null && token.refreshToken.isNotEmpty) {
        try {
          // --- ETAP 1: ŻĄDANIE O NOWY TOKEN ---
          final refreshResponse = await _refreshDio.post(
            '/api/v1/auth/refresh',
            data: {'refresh_token': token.refreshToken},
          );

          // --- ETAP 2: PARSOWANIE I ZAPIS ---
          final newToken = AuthToken.fromJson(refreshResponse.data);
          await _storage.saveToken(newToken);

          // --- ETAP 3: AKTUALIZACJA ORYGINALNEGO ZAPYTANIA ---
          // Podmieniamy stary, wygasły token na nowy w nagłówku
          err.requestOptions.headers['Authorization'] = 'Bearer ${newToken.accessToken}';
          // Oznaczamy zapytanie jako "ponawiane", żeby nie wpaść w pętlę
          err.requestOptions.extra['isRetry'] = true;

          // --- ETAP 4: PONOWIENIE ORYGINALNEGO ZAPYTANIA ---
          // Tworzymy na szybko czyste Dio, aby powtórzyć zablokowane zapytanie.
          // Używamy wszystkich starych opcji (adres, body, parametry), ale z nowym tokenem.
          final retryDio = Dio();
          final retryResponse = await retryDio.fetch(err.requestOptions);

          // SUKCES! Zwracamy odpowiedź wyżej. UI aplikacji nawet nie dowie się,
          // że po drodze wystąpił jakikolwiek błąd 401.
          return handler.resolve(retryResponse);

        } catch (refreshError) {
          // Jeśli odświeżanie tokena się nie powiodło (np. Refresh Token wygasł po 7 dniach):
          _forceLogout();
          return handler.next(err);
        }
      } else {
        // Brak Refresh Tokena w pamięci - twarde wylogowanie
        _forceLogout();
        return handler.next(err);
      }
    }

    // Jeśli to inny błąd niż 401 (np. 500, 404, brak internetu), puszczamy go dalej do UI
    return handler.next(err);
  }

  // Prywatna metoda pomocnicza do wylogowywania
  void _forceLogout() {
    _ref.read(authControllerProvider.notifier).logout();
  }
}