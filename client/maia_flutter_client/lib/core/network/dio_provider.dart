// lib/core/network/dio_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/token_storage.dart'; // Import storage

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://dev-sentences.rafal-kruszyna.org', // lub gateway URL
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  // Dodajemy interceptor
  final storage = ref.watch(tokenStorageProvider);
  
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Przed każdym zapytaniem pobierz token z bezpiecznego magazynu
      final token = await storage.getToken();
      
      // Jeśli mamy token, dodaj nagłówek
      if (token != null) {
        options.headers['Authorization'] = 'Bearer ${token.accessToken}';
      }
      
      return handler.next(options);
    },
    onError: (DioException error, handler) async {
      // Obsługa 401 (Token wygasł)
      if (error.response?.statusCode == 401) {
        // TU w przyszłości dodasz logikę "Refresh Token"
        // Na razie proste wylogowanie w UI jeśli token wygasł
      }
      return handler.next(error);
    }
  ));

  return dio;
});