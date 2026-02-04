import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/token_storage.dart';

// Stan sesji: Interesuje nas tylko czy user jest zalogowany
class AuthState {
  final bool isAuthenticated;
  final bool isAppLoading; // Do splash screena przy starcie

  const AuthState({
    this.isAuthenticated = false,
    this.isAppLoading = true, // Domyślnie true, bo przy starcie sprawdzamy storage
  });
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
      state = const AuthState(isAuthenticated: true, isAppLoading: false);
    } else {
      state = const AuthState(isAuthenticated: false, isAppLoading: false);
    }
  }

  // Metoda wywoływana przez LoginController/RegisterController po sukcesie
  void setAuthenticated(bool isAuthenticated) {
    state = AuthState(isAuthenticated: isAuthenticated, isAppLoading: false);
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
    state = const AuthState(isAuthenticated: false, isAppLoading: false);
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
