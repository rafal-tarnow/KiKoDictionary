import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/network/api_error_handler.dart';
import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import '../domain/exceptions/auth_exceptions.dart';

// Stan autentykacji
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? usernameSuggestion;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true, // Domyślnie true, bo przy starcie sprawdzamy storage
    this.error,
    this.usernameSuggestion,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? usernameSuggestion,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Uwaga: w prostym copyWith null nie nadpisuje wartości, ale tutaj to wystarczy
      usernameSuggestion:
          usernameSuggestion ?? this.usernameSuggestion, // <--- I TUTAJ
    );
  }

  // Helper do czyszczenia błędów
  AuthState clearErrors() {
    return AuthState(
      isAuthenticated: isAuthenticated,
      isLoading: isLoading,
      error: null,
      usernameSuggestion: null,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _storage;

  AuthController(this._repository, this._storage) : super(const AuthState()) {
    checkAuthStatus();
  }

  // Sprawdza przy starcie apki, czy mamy token
  Future<void> checkAuthStatus() async {
    final token = await _storage.getToken();
    if (token != null) {
      // Opcjonalnie: Tutaj można strzelić do /api/v1/users/me żeby sprawdzić czy token jest nadal ważny
      state = const AuthState(isAuthenticated: true, isLoading: false);
    } else {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  // Metoda pomocnicza dla UI, żeby wyczyścić sugestię gdy użytkownik zaczyna pisać
  void clearSuggestion() {
    if (state.usernameSuggestion != null || state.error != null) {
      state = state.clearErrors();
    }
  }

  Future<bool> login(String username, String password) async {
    // Resetujemy błąd i włączamy loading
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _repository.login(
        username: username,
        password: password,
      );
      await _storage.saveToken(token);

      // SUKCES
      state = const AuthState(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      // BŁĄD: Używamy Twojego ApiErrorHandler, który już obsługuje 400, 401, 422 itd.
      final msg = ApiErrorHandler.getErrorMessage(e);

      state = state.copyWith(
        isLoading: false,
        error: msg,
        isAuthenticated: false,
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String captchaId,
    required String captchaAnswer,
  }) async {
    // Czyścimy stan przed startem (ustawiamy error i suggestion na null ręcznie w copyWith,
    // ale copyWith w dart standardowo ignoruje null, więc lepiej stworzyć nowy stan lub zmodyfikować copyWith.
    // Dla uproszczenia tutaj przyjmijmy, że isLoading nadpisuje UI).
    state = const AuthState(isLoading: true);

    try {
      await _repository.register(
        email: email,
        username: username,
        password: password,
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on UsernameTakenException catch (e) {
      // --- TUTAJ ŁAPIEMY SUGESTIĘ ---
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        usernameSuggestion: e.suggestion,
      );
      return false;
    } catch (e) {
      final msg = ApiErrorHandler.getErrorMessage(e);
      // Musimy wyzerować suggestion, jeśli wystąpił INNY błąd
      state = state.copyWith(isLoading: false, error: msg);
      // W idealnym świecie copyWith powinno umieć ustawić null,
      // ale tutaj po prostu nadpiszemy stan bez suggestion w kolejnym kroku UI.
      return false;
    }
  }

  Future<void> logout() async {
    final token = await _storage.getToken();
    if (token != null) {
      try {
        await _repository.logout(token.refreshToken);
      } catch (_) {
        // Ignorujemy błędy sieciowe przy wylogowaniu
      }
    }
    await _storage.clearToken();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

// Globalny provider stanu autentykacji
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(tokenStorageProvider),
    );
  },
);
