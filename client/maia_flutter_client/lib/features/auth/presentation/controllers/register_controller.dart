import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../data/auth_repository.dart';


class RegisterState {
  final bool isLoading;
  final String? error;

  // Usunięto 'usernameSuggestion'
  const RegisterState({
    this.isLoading = false, 
    this.error, 
  });

  RegisterState copyWith({bool? isLoading, String? error}) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: error, 
    );
  }
}


class RegisterController extends StateNotifier<RegisterState> {
  final AuthRepository _authRepository;

  RegisterController(this._authRepository) : super(const RegisterState());


  Future<bool> register({
    required String email,
    required String password,
    required String captchaId,
    required String captchaAnswer,
  }) async {
    state = const RegisterState(isLoading: true); 

    try {
      await _authRepository.register(
        email: email,
        password: password, // <-- Brak loginu
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
      );
      state = state.copyWith(isLoading: false);
      return true;
      
    // Usunięto obsługę wyjątku UsernameTakenException
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