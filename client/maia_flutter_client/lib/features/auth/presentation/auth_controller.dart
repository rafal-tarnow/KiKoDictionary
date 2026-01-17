import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/network/api_error_handler.dart';
import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import '../data/models/auth_token.dart';

// Stan autentykacji
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false, 
    this.isLoading = true, // Domyślnie true, bo przy starcie sprawdzamy storage
    this.error
  });
  
  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repository.login(username: username, password: password);
      await _storage.saveToken(token);
      state = const AuthState(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Błąd logowania. Sprawdź dane.");
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        email: email,
        username: username,
        password: password,
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
      );
      state = state.copyWith(isLoading: false);
      return true; // Sukces rejestracji
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Błąd rejestracji. ${ApiErrorHandler.getErrorMessage(e)}");
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
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});