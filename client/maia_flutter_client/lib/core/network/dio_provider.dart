import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart'; // Import configu
import 'auth_interceptor_provider.dart'; // Import interceptora

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.sentencesBaseUrl, // Adres mikroserwisu zdań
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // Używamy tego samego interceptora co w authDioProvider (DRY!)
  final authInterceptor = ref.watch(authInterceptorProvider);
  dio.interceptors.add(authInterceptor);

  return dio;
});