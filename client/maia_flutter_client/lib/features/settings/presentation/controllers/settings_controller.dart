// ================= ZMIANA CAŁY PLIK =================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user/data/user_repository.dart'; // NOWE
import '../../../user/presentation/controllers/user_controller.dart'; // NOWE

class SettingsState {
  final bool isLoading;
  final String? error;

  const SettingsState({this.isLoading = false, this.error});

  SettingsState copyWith({bool? isLoading, String? error}) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final AuthController _authController;
  final Ref _ref;

  SettingsController(this._authRepo, this._userRepo, this._authController, this._ref) 
      : super(const SettingsState());

  // === NOWA FUNKCJA DO JĘZYKA ===
  Future<bool> updateLanguage(String newLangCode) async {
    state = const SettingsState(isLoading: true, error: null);
    try {
      // 1. Zapis na serwerze
      await _userRepo.updateProfile(nativeLanguage: newLangCode);
      
      // 2. Odświeżenie globalnego stanu aplikacji
      await _ref.read(userControllerProvider.notifier).fetchUser();
      
      state = const SettingsState(isLoading: false);
      return true;
    } catch (e) {
      final msg = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  // === USUNIĘCIE KONTA BEZ ZMIAN ===
  Future<bool> deleteAccount() async {
    state = const SettingsState(isLoading: true, error: null);
    try {
      await _authRepo.deleteAccount();
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

final settingsControllerProvider = StateNotifierProvider.autoDispose<SettingsController, SettingsState>((ref) {
  return SettingsController(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider), // Dodano
    ref.read(authControllerProvider.notifier),
    ref,
  );
});