import 'package:dio/dio.dart';

class ApiErrorHandler {
  // Metoda statyczna, działająca jak fabryka komunikatów
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Upłynął limit czasu połączenia. Sprawdź internet.";
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 404) return "Nie znaleziono zasobu na serwerze (404).";
          if (statusCode == 500) return "Błąd wewnętrzny serwera (500).";
          return "Błąd serwera: $statusCode";

        case DioExceptionType.connectionError:
          return "Brak połączenia z serwerem. Upewnij się, że masz internet lub serwer jest dostępny.";

        case DioExceptionType.cancel:
          return "Żądanie zostało anulowane.";

        default:
          return "Wystąpił nieznany błąd sieciowy.";
      }
    } else {
      // Błędy nietypowe (np. błąd parsowania JSON, błąd w kodzie Dart)
      return "Wystąpił niespodziewany błąd: ${error.toString()}"; // W wersji PRO tutaj logujemy do Sentry/Crashlytics
    }
  }
}