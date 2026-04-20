import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/navigation_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/token_storage.dart';
import '../../../user/presentation/controllers/user_controller.dart';
import '../../../sentences/presentation/sentences_provider.dart';

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
  final Ref _ref;

  AuthController(this._repository, this._storage, this._ref) : super(const AuthState()) {
    checkAuthStatus();
  }

  // Sprawdza przy starcie apki, czy mamy token
  Future<void> checkAuthStatus() async {
    final token = await _storage.getToken();
    if (token != null) {
      // Opcjonalnie: Tutaj można strzelić do /api/v1/users/me żeby sprawdzić czy token jest nadal ważny
      state = const AuthState(isAuthenticated: true, isAppLoading: false);

      // ================= [ZMIANA 1]: Oczekujemy na załadowanie usera =================
      await _ref.read(userControllerProvider.notifier).fetchUser();
      
      // Sprawdzamy status usera i wymuszamy nawigację!
      _checkOnboardingAndRedirect();
      // ==================================================================================

      // ZMIANA: Pobierz prywatne zdania po wejściu do aplikacji
      _ref.read(sentencesProvider.notifier).loadSentences(page: 1);
    } else {
      state = const AuthState(isAuthenticated: false, isAppLoading: false);
    }
  }

  // Metoda wywoływana przez LoginController/RegisterController po sukcesie
  void setAuthenticated(bool isAuthenticated) async{
    state = AuthState(isAuthenticated: isAuthenticated, isAppLoading: false);
    if(isAuthenticated){
      // ================= [ZMIANA 2]: Oczekujemy na załadowanie usera po logowaniu =================
      await _ref.read(userControllerProvider.notifier).fetchUser();
      
      _checkOnboardingAndRedirect();
      // ============================================================================================
      // ZMIANA: Zmuś aplikację do załadowania Zdań NOWEGO użytkownika
      _ref.read(sentencesProvider.notifier).loadSentences(page: 1);
    }
  }


  void _checkOnboardingAndRedirect() {
    final user = _ref.read(userControllerProvider).valueOrNull;
    if (user != null && user.profile != null) {
      if (user.profile!.isOnboardingCompleted == false) {
        // Przekierowanie na Index 11 (OnboardingPage) z ominięciem menu głównego
        _ref.read(navigationIndexProvider.notifier).state = 11;
      }
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

    // ZMIANA: Czyścimy pamięć globalną (User + Sentences) z danych starego użytkownika!
    _ref.read(userControllerProvider.notifier).clearUser();
    _ref.read(sentencesProvider.notifier).clearData(); 
    
    state = const AuthState(isAuthenticated: false, isAppLoading: false);
  }
}

// Globalny provider stanu autentykacji
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(tokenStorageProvider),
      ref,
    );
  },
);
