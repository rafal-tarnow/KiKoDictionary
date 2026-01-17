import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/auth_interceptor_provider.dart';

final authDioProvider = Provider<Dio>((ref) {
  // 1. Konfiguracja bazowa
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.authBaseUrl, // Używamy adresu z konfigu
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // 2. Dodajemy wspólny interceptor autentykacji
  // (Potrzebny np. do endpointu /logout lub /users/me)
  final authInterceptor = ref.watch(authInterceptorProvider);
  dio.interceptors.add(authInterceptor);

  // 3. Opcjonalnie: Dodaj PrettyDioLogger w trybie debug (jeśli używasz)
  
  return dio;
});