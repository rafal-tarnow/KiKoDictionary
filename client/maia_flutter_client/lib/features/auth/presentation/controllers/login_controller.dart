import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../data/auth_repository.dart';
import '../../data/token_storage.dart';
import 'auth_controller.dart';

// Stan formularza logowania
class LoginState {
  final bool isLoading;
  final String? error;

  const LoginState({this.isLoading = false, this.error});

  LoginState copyWith({bool? isLoading, String? error}) {
    // Uwaga: error: error (bez nulla) pozwala wyczyścić błąd przekazując null
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error, 
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  // Potrzebujemy dostępu do AuthController, żeby zmienić stan globalny po sukcesie
  final AuthController _authController;

  LoginController(this._authRepository, this._tokenStorage, this._authController)
      : super(const LoginState());

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _authRepository.login(
        username: username, 
        password: password
      );
      
      await _tokenStorage.saveToken(token);
      
      // Sukces lokalny
      state = state.copyWith(isLoading: false);
      
      // Aktualizacja stanu globalnego aplikacji
      _authController.setAuthenticated(true);
      
      return true;
    } catch (e) {
      final msg = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }
}

// Używamy autoDispose, aby stan czyścił się, gdy kontroler nie jest obserwowany 
// (choć przy IndexedStack on "żyje", ale to dobra praktyka dla formularzy)
final loginControllerProvider = StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
    ref.read(authControllerProvider.notifier), // read, bo potrzebujemy metody, nie stanu
  );
});