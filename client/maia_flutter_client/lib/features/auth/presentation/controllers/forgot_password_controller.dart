import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../data/auth_repository.dart';

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
    String? error, 
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
  final AuthRepository _authRepository;

  ForgotPasswordController(this._authRepository) : super(const ForgotPasswordState());

  Future<bool> sendResetLink(String email) async {
    // Reset stanu przed akcją (czyścimy też error z poprzedniej próby)
    state = const ForgotPasswordState(isLoading: true, error: null);

    try {
      await _authRepository.forgotPassword(email);
      
      // Sukces (Status 202 Accepted)
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      final msg = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  void resetState() {
    state = const ForgotPasswordState();
  }
}

// Provider
final forgotPasswordControllerProvider = 
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(ref.watch(authRepositoryProvider));
});