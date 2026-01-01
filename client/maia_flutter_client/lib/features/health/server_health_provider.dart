import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum określający stan serwera
enum ServerStatus { loading, online, offline }

// Provider, który tworzy osobną instancję Dio dla health checków.
// Dlaczego osobna? Bo chcemy krótki timeout (np. 2 sekundy), a nie domyślny.
final healthCheckDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3), // Krótki timeout
    receiveTimeout: const Duration(seconds: 3),
    validateStatus: (status) {
      // Uznajemy za sukces wszystko poniżej 500 (nawet 404 oznacza, że serwer odpowiada)
      return status != null && status < 500;
    },
  ));
});

// Family Provider: Tworzy logikę sprawdzania dla konkretnego adresu URL.
// Zwraca ServerStatus.
final serverHealthProvider = FutureProvider.family<ServerStatus, String>((ref, url) async {
  final dio = ref.watch(healthCheckDioProvider);
  
  try {
    // Wysyłamy proste zapytanie GET lub HEAD. 
    // Jeśli API ma endpoint /health, warto go użyć. Jeśli nie, root '/' wystarczy.
    // Dodajemy cache breaker, żeby przeglądarka/dio nie cache'owały wyniku
    final checkUrl = '$url/?t=${DateTime.now().millisecondsSinceEpoch}';
    
    await dio.get(checkUrl);
    
    return ServerStatus.online;
  } catch (e) {
    // Jeśli timeout lub błąd sieci -> offline
    return ServerStatus.offline;
  }
});