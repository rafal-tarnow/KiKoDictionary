import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider dedykowany dla mikroserwisu Captcha (port 8001)
final captchaDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // Dostosuj adres IP do swojego środowiska (podobnie jak w dio_provider.dart)
    // Jeśli używasz emulatora: http://10.0.2.2:8001
    // Jeśli fizyczne urządzenie/web: Twój adres LAN lub domena
    //baseUrl: 'http://127.0.0.1:8001', 
    baseUrl: 'https://dev-captcha.rafal-kruszyna.org',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  return dio;
});