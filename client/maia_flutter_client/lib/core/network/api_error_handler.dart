import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet connection.";

        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);

        case DioExceptionType.connectionError:
          return "Unable to connect to the server. Please check your internet connection.";

        case DioExceptionType.cancel:
          return "Request was canceled.";

        default:
          return "An unknown network error occurred.";
      }
    } else {
      return "An unexpected error occurred: ${error.toString()}";
    }
  }

static String _handleBadResponse(Response? response) {
    if (response == null) return "Unknown server error.";

    final dynamic data = response.data;
    final int? statusCode = response.statusCode;

    // KROK 1: Sprawdź, czy serwer przysłał konkretny komunikat błędu.
    if (data is Map) {
      // Obsługa naszego Custom Validation Error z FastAPI (np. za długi tekst)
      if (statusCode == 422 &&
          data.containsKey('details') &&
          data['details'] is List) {
        final list = data['details'] as List;
        if (list.isNotEmpty && list.first is Map) {
          final backendMsg =
              list.first['message']?.toString() ?? "Data validation error.";
          
          // ================= [ZMIANA]: Tłumaczymy przed zwróceniem! =================
          return _translateMessage(backendMsg);
        }
      }
      // =========================================================================================

      // Obsługa błędu 422 (FastAPI Validation Error)
      if (statusCode == 422 && data['detail'] is List) {
        final list = data['detail'] as List;
        if (list.isNotEmpty && list.first is Map) {
          final firstMsg = list.first['msg'];

          // --- POPRAWKA TUTAJ ---
          // Musimy przetłumaczyć wiadomość wyciągniętą z listy!
          final translatedMsg = _translateMessage(firstMsg.toString());

          return "Validation error: $translatedMsg";
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
        return "Bad request (400).";
      case 401:
        return "Authentication failed. Please log in again.";
      case 403:
        return "Access denied.";
      case 404:
        return "Resource not found (404).";
      case 409:
        return "Data conflict (409).";
      case 429:
        return "Too many requests. Please slow down.";
      case 500:
      case 502:
        return "Server error ($statusCode). Please try again later.";
      case 503:
        return "Service unavailable (maintenance or overload).";
      default:
        return "An error occurred ($statusCode).";
    }
  }

  static String _translateMessage(String msg) {
    // Prosty słownik tłumaczeń najczęstszych błędów z backendu

    // --- NOWE TŁUMACZENIA DLA USERNAME (Auth Service) ---
    if (msg.contains("Username must be at least 3 characters long")) {
      return "Username must be at least 3 characters long.";
    }
    if (msg.contains("Username cannot be longer than 30 characters")) {
      return "Username cannot exceed 30 characters.";
    }
    if (msg.contains("Username can only contain letters, numbers")) {
      return "Username can only contain letters, numbers, underscores (_), and hyphens (-).";
    }
    if (msg.contains("This username is reserved")) {
      return "This username is reserved and cannot be used.";
    }
    if (msg.contains("Username cannot contain '@' symbol")) {
      return "Username cannot contain the '@' symbol.";
    }
    if (msg.contains("consecutive underscores or hyphens")) {
      return "Username cannot contain consecutive underscores or hyphens.";
    }
    // ----------------------------------------------------

    if (msg.contains("User with this email already exists")) {
      return "A user with this email address already exists.";
    }
    if (msg.contains("User with this username already exists")) {
      return "This username is already taken.";
    }
    if (msg.contains("Username already taken")) {
      return "This username is already taken.";
    }
    if (msg.contains("Incorrect email or password")) {
      return "Incorrect email or password.";
    }
    if (msg.contains("Inactive user")) {
      return "This account is currently inactive.";
    }
    if (msg.contains("Invalid captcha")) {
      return "Invalid Captcha code. Please try again.";
    }
    if (msg.contains("Invalid CAPTCHA answer")) {
      return "Invalid Captcha code. Please try again.";
    }
    if (msg.contains("Email already registered")) {
      return "This email address is already registered.";
    }
    if (msg.contains("value is not a valid email address")) {
      return "Invalid email format.";
    }
    if (msg.contains("Password must be at least 8 characters long")) {
      return "Password must be at least 8 characters long.";
    }
    if (msg.contains("Password must contain at least one digit")) {
      return "Password must contain at least one number.";
    }
    if (msg.contains("Password must contain at least one letter")) {
      return "Password must contain at least one letter.";
    }
    if (msg.contains("String should have at least 8 characters")) {
      return "Value is too short (minimum 8 characters required).";
    }
    //auth service error
    if (msg.contains(
      "Database error: Resource is locked. Service temporarily unavailable.",
    )) {
      return "The service is temporarily busy. Please try again in a moment.";
    }
    //auth service error
    if (msg.contains("Database error: Internal operation failed.")) {
      return "An internal server error occurred. Please try again.";
    }

    if (msg.contains("is too long. Current limit is")) {
      // Możesz zostawić to bez zmian (zwróci np. "Text in field 'original_text' is too long. Current limit is 150 characters.")
      // Albo wygładzić to dla użytkownika, wycinając nazwy systemowych pól:
      if (msg.contains("original_text") || msg.contains("translated_text")) {
          return "The provided text exceeds the character limit (150).";
      }
      return msg;
    }

    // Jeśli nie mamy tłumaczenia, zwracamy oryginał (np. "Password is too short")
    return msg;
  }
}
