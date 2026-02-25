import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

// Stan dla ustawień
class SettingsState {
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({bool? isLoading, String? error}) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Przekazanie nulla wyczyści błąd
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final AuthRepository _repository;
  final AuthController _authController;

  SettingsController(this._repository, this._authController) : super(const SettingsState());

  Future<bool> deleteAccount() async {
    state = const SettingsState(isLoading: true, error: null);

    try {
      // Wywołanie API do usunięcia konta
      await _repository.deleteAccount();
      
      // Jeżeli API zwróci 204, wylogowujemy użytkownika lokalnie z aplikacji
      // i czyścimy tokeny. Wywołujemy globalny AuthController.
      await _authController.logout();
      
      state = const SettingsState(isLoading: false);
      return true;
    } catch (e) {
      final msg = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }
}

// Provider kontrolera
final settingsControllerProvider = StateNotifierProvider.autoDispose<SettingsController, SettingsState>((ref) {
  return SettingsController(
    ref.watch(authRepositoryProvider),
    ref.read(authControllerProvider.notifier),
  );
});