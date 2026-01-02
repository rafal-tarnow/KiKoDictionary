import 'package:dio/dio.dart';

class HealthCheckService {
  final Dio _dio;

  HealthCheckService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          contentType: 'application/json',
          validateStatus: (status) => status == 200, // Tylko 200 nas interesuje
        ));

  /// Sprawdza konkretny endpoint wymagany przez C++ logic
  Future<bool> checkHost(String baseUrl) async {
    // Usuń slash na końcu jeśli jest
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    
    // Konkretny endpoint z Twojego kodu C++
    final targetUrl = '$cleanUrl/health/live';

    try {
      // Cache breaker, żeby nie pobierać starego wyniku
      final response = await _dio.get(
        targetUrl, 
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      );

      if (response.statusCode == 200 && response.data is Map) {
        // Sprawdzenie logiki biznesowej: {"status": "ok"}
        return response.data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}