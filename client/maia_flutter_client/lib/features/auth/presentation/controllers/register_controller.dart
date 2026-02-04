import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../data/auth_repository.dart';
import '../../domain/exceptions/auth_exceptions.dart';

class RegisterState {
  final bool isLoading;
  final String? error;
  final String? usernameSuggestion;

  const RegisterState({
    this.isLoading = false, 
    this.error, 
    this.usernameSuggestion
  });

  RegisterState copyWith({bool? isLoading, String? error, String? usernameSuggestion}) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: error, 
      usernameSuggestion: usernameSuggestion,
    );
  }
  
  // Helper do czyszczenia sugestii
  RegisterState clearSuggestion() {
    return RegisterState(isLoading: isLoading, error: null, usernameSuggestion: null);
  }
}

class RegisterController extends StateNotifier<RegisterState> {
  final AuthRepository _authRepository;

  RegisterController(this._authRepository) : super(const RegisterState());

  void clearSuggestion() {
    if (state.usernameSuggestion != null || state.error != null) {
      state = state.clearSuggestion();
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String captchaId,
    required String captchaAnswer,
  }) async {
    state = const RegisterState(isLoading: true); // Reset stanu przy starcie

    try {
      await _authRepository.register(
        email: email,
        username: username,
        password: password,
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
      );
      state = state.copyWith(isLoading: false);
      // Rejestracja zazwyczaj nie loguje z automatu (chyba że API tak działa),
      // więc nie ustawiamy tutaj authController.setAuthenticated(true).
      // Zwracamy true, żeby UI wiedział o sukcesie.
      return true;
    } on UsernameTakenException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        usernameSuggestion: e.suggestion,
      );
      return false;
    } catch (e) {
      final msg = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }
}

final registerControllerProvider = StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
  return RegisterController(ref.watch(authRepositoryProvider));
});