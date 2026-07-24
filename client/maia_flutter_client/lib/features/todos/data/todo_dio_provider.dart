import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_interceptor_provider.dart';

final todoDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.todosBaseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  // Omijamy problem autoryzacji - wstrzykujemy ten sam genialny interceptor!
  dio.interceptors.add(ref.watch(authInterceptorProvider));

  return dio;
});