import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/captcha_repository.dart';
import '../data/models/captcha_model.dart';
import '../../../../core/network/api_error_handler.dart';

// Stan dla naszego kontrolera
class CaptchaState {
  final CaptchaModel? captcha; // Obecny obrazek i ID
  final bool isLoading;
  final String? errorMessage;
  final bool? isVerified; // null = nie sprawdzano, true = ok, false = źle

  const CaptchaState({
    this.captcha,
    this.isLoading = false,
    this.errorMessage,
    this.isVerified,
  });

  CaptchaState copyWith({
    CaptchaModel? captcha,
    bool? isLoading,
    String? errorMessage,
    bool? isVerified,
  }) {
    return CaptchaState(
      captcha: captcha ?? this.captcha,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Jeśli null to czyścimy błąd
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class CaptchaController extends StateNotifier<CaptchaState> {
  final CaptchaRepository _repository;

  CaptchaController(this._repository) : super(const CaptchaState()) {
    // Automatycznie pobierz captchę przy starcie
    fetchCaptcha();
  }

  Future<void> fetchCaptcha() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isVerified: null);
    try {
      final captcha = await _repository.generateCaptcha();
      state = state.copyWith(
        isLoading: false,
        captcha: captcha,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.getErrorMessage(e),
      );
    }
  }

  Future<bool> verifyCaptcha(String answer) async {
    if (state.captcha == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isValid = await _repository.verifyCaptcha(
        CaptchaVerifyRequest(id: state.captcha!.id, answer: answer),
      );

      state = state.copyWith(
        isLoading: false,
        isVerified: isValid,
      );
      
      // Jeśli walidacja nie przeszła, można automatycznie odświeżyć captchę, 
      // bo zazwyczaj token jest jednorazowy.
      if (!isValid) {
         // Opcjonalnie: await fetchCaptcha(); 
         // Wiele systemów wymaga nowej captchy po błędnej próbie.
      }
      
      return isValid;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.getErrorMessage(e),
        isVerified: false,
      );
      return false;
    }
  }
  
  // Metoda pomocnicza do resetowania stanu weryfikacji (np. gdy użytkownik zaczyna pisać)
  void resetVerificationStatus() {
    if (state.isVerified != null) {
      state = state.copyWith(isVerified: null);
    }
  }
}

// Używamy .autoDispose, aby stan się czyścił po wyjściu z ekranu
final captchaControllerProvider = 
    StateNotifierProvider.autoDispose<CaptchaController, CaptchaState>((ref) {
  final repo = ref.watch(captchaRepositoryProvider);
  return CaptchaController(repo);
});