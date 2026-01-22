import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Upłynął limit czasu połączenia. Sprawdź internet.";

        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);

        case DioExceptionType.connectionError:
          return "Brak połączenia z serwerem. Sprawdź internet.";

        case DioExceptionType.cancel:
          return "Żądanie zostało anulowane.";

        default:
          return "Wystąpił nieznany błąd sieciowy.";
      }
    } else {
      return "Wystąpił niespodziewany błąd: ${error.toString()}";
    }
  }

  static String _handleBadResponse(Response? response) {
    if (response == null) return "Nieznany błąd serwera.";

    final dynamic data = response.data;
    final int? statusCode = response.statusCode;

    // KROK 1: Sprawdź, czy serwer przysłał konkretny komunikat błędu.
    if (data is Map) {
      // Obsługa błędu 422 (FastAPI Validation Error)
      if (statusCode == 422 && data['detail'] is List) {
        final list = data['detail'] as List;
        if (list.isNotEmpty && list.first is Map) {
          final firstMsg = list.first['msg'];

          // --- POPRAWKA TUTAJ ---
          // Musimy przetłumaczyć wiadomość wyciągniętą z listy!
          final translatedMsg = _translateMessage(firstMsg.toString());

          return "Błąd walidacji: $translatedMsg";
        }
      }

      // Standardowa obsługa (400, 401, 409...) - detail to String
      if (data['detail'] != null && data['detail'] is String) {
        return _translateMessage(data['detail']);
      }
    }

    // KROK 2: Fallback (Estymacja po kodzie)
    switch (statusCode) {
      case 400:
        return "Nieprawidłowe żądanie (400).";
      case 401:
        return "Błąd autentykacji. Zaloguj się ponownie.";
      case 403:
        return "Brak dostępu do zasobu.";
      case 404:
        return "Nie znaleziono zasobu (404).";
      case 409:
        return "Konflikt danych (409).";
      case 429:
        return "Zbyt wiele zapytań. Zwolnij chwilę.";
      case 500:
      case 502:
        return "Błąd serwera ($statusCode). Spróbuj później.";
      case 503:
        return "Serwer jest niedostępny (Trwają prace techniczne lub przeciążenie).";
      default:
        return "Wystąpił błąd ($statusCode).";
    }
  }

  static String _translateMessage(String msg) {
    // Prosty słownik tłumaczeń najczęstszych błędów z backendu
    if (msg.contains("User with this email already exists")) {
      return "Użytkownik o tym adresie email już istnieje.";
    }
    if (msg.contains("User with this username already exists")) {
      return "Ta nazwa użytkownika jest już zajęta.";
    }
    if (msg.contains("Username already taken")) {
      return "Ta nazwa użytkownika jest już zajęta.";
    }
    if (msg.contains("Incorrect username or password")) {
      return "Niepoprawna nazwa użytkownika lub hasło.";
    }
    if (msg.contains("Inactive user")) {
      return "Konto jest nieaktywne.";
    }
    if (msg.contains("Invalid captcha")) {
      return "Niepoprawny kod Captcha.";
    }
    if (msg.contains("Invalid CAPTCHA answer")) {
      return "Niepoprawny kod Captcha.";
    }
    if (msg.contains("Email already registered")) {
      return "Ten adres email jest już zarejestrowany.";
    }
    if (msg.contains("value is not a valid email address")) {
      return "Niepoprawny format adresu email.";
    }
    if (msg.contains("Password must be at least 6 characters long")) {
      return "Hasło musi mieć co najmniej 6 znaków.";
    }
    if (msg.contains("Password must contain at least one digit")) {
      return "Hasło musi zawierać co najmniej jedną cyfrę.";
    }
    if (msg.contains("Password must contain at least one letter")) {
      return "Hasło musi zawierać co najmniej jedną literę.";
    }
    if (msg.contains("String should have at least")) {
      return "Wartość jest za krótka (wymagane min. 6 znaków).";
    }
    //auth service error
    if(msg.contains("Database error: Resource is locked. Service temporarily unavailable.")){
      return "Serwis jest chwilowo zajęty (baza danych zablokowana). Spróbuj ponownie za chwilę.";
    }
    //auth service error
    if(msg.contains("Database error: Internal operation failed.")){
      return "Wystąpił wewnętrzny błąd bazy danych. Spróbuj ponownie.";
    }

    // Jeśli nie mamy tłumaczenia, zwracamy oryginał (np. "Password is too short")
    return msg;
  }
}