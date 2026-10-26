import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/auth_interceptor_provider.dart';

/// Dio dla projects-microservice (port 8005). Wspólny interceptor dokleja
/// token i odświeża go po 401 - tak jak w pozostałych mikroserwisach.
final projectsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.projectsBaseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  dio.interceptors.add(ref.watch(authInterceptorProvider));

  return dio;
});
