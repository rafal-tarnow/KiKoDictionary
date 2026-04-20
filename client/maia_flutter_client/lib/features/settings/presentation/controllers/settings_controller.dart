// ================= ZMIANA CAŁY PLIK =================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user/data/user_repository.dart'; // NOWE
import '../../../user/presentation/controllers/user_controller.dart'; // NOWE
import '../../../user/domain/exceptions/user_exceptions.dart';

class SettingsState {
  final bool isLoading;
  final String? error;
  // ================= ZMIANA 2: Nowe pole dla sugestii =================
  final List<String>? usernameSuggestions;

  const SettingsState({
    this.isLoading = false, 
    this.error,
    this.usernameSuggestions,
  });

  SettingsState copyWith({
    bool? isLoading, 
    String? error,
    List<String>? usernameSuggestions,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Tu nie dajemy ??, by móc nadpisać nullem
      usernameSuggestions: usernameSuggestions, // Tu też nie, by móc wyczyścić
    );
  }

  // Funkcja pomocnicza (Clean Code)
  SettingsState clearErrorAndSuggestions() {
    return SettingsState(isLoading: isLoading, error: null, usernameSuggestions: null);
  }
  // ====================================================================
}

class SettingsController extends StateNotifier<SettingsState> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final AuthController _authController;
  final Ref _ref;

  SettingsController(this._authRepo, this._userRepo, this._authController, this._ref) 
      : super(const SettingsState());

  // ================= ZMIANA 3: Funkcja czyszcząca UI z błędów w locie =================
  void clearUsernameError() {
    if (state.error != null || state.usernameSuggestions != null) {
      state = state.clearErrorAndSuggestions();
    }
  }

  Future<bool> updateUsername(String newUsername) async {
    state = state.copyWith(isLoading: true, error: null, usernameSuggestions: null);
    try {
      // 1. Strzał do API
      await _userRepo.updateUsername(newUsername: newUsername);
      
      // 2. Jeśli sukces -> Odświeżamy globalny stan Usera (żeby avatar w AppBar się zmienił!)
      await _ref.read(userControllerProvider.notifier).fetchUser();
      
      state = state.copyWith(isLoading: false);
      return true;

    } on UsernameConflictException catch (e) {
      // 3. Jeśli konflikt -> Przekazujemy sugestie z backendu do UI
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        usernameSuggestions: e.suggestions,
      );
      return false;

    } catch (e) {
      // 4. Inne błędy (np. 422 zbyt krótka nazwa, brak neta)
      final msg = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

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

// === NOWA FUNKCJA DLA ONBOARDINGU ===
  Future<bool> completeOnboarding(String newLangCode) async {
    state = const SettingsState(isLoading: true, error: null);
    try {
      // Zapisujemy język ORAZ flagę ukończenia onboardingu
      await _userRepo.updateProfile(
        nativeLanguage: newLangCode,
        isOnboardingCompleted: true, // <--- TO JEST KLUCZOWE
      );
      
      // Odświeżenie globalnego stanu (flaga zmieni się z false na true w pamięci apki)
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