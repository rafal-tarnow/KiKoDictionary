import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stan widoku
class ForgotPasswordState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? error, // null nie czyści błędu automatycznie w tym patternie, ale tu uprościmy
    bool? isSuccess,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  // Tutaj w przyszłości wstrzykniesz AuthRepository
  ForgotPasswordController() : super(const ForgotPasswordState());

  Future<bool> sendResetLink(String email) async {
    // Reset stanu przed akcją
    state = const ForgotPasswordState(isLoading: true);

    try {
      // --- SYMULACJA ZAPYTANIA DO API ---
      await Future.delayed(const Duration(seconds: 2));
      
      // Tu w przyszłości: await _authRepository.forgotPassword(email);
      
      // Sukces
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      // Błąd
      state = state.copyWith(isLoading: false, error: "Wystąpił błąd. Spróbuj ponownie.");
      return false;
    }
  }

  void resetState() {
    state = const ForgotPasswordState();
  }
}

// Provider (autoDispose czyści stan po wyjściu z ekranu)
final forgotPasswordControllerProvider = 
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController();
});