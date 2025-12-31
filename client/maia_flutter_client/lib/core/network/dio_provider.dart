import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider zwracający skonfigurowaną instancję Dio.
// Zmień baseUrl na adres swojego lokalnego serwera (dla emulatora Androida to zazwyczaj 10.0.2.2)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    //baseUrl: 'https://maia-sentences.rafal-kruszyna.org', // Jeśli API stoi lokalnie na porcie 8003
    //baseUrl: 'http://localhost:8003', // Jeśli API stoi lokalnie na porcie 8003
    baseUrl: 'http://10.139.19.47:8003',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  return dio;
});