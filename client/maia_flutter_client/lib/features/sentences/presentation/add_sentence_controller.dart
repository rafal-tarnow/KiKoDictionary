import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_create_model.dart';
import '../data/sentences_repository.dart';
import 'sentences_provider.dart'; // Potrzebne, żeby odświeżyć listę po sukcesie
import '../../../core/network/api_error_handler.dart';

// Controller zarządza stanem operacji dodawania.
// AsyncValue<void> oznacza, że operacja nie zwraca wartości, ale śledzimy jej status.
class AddSentenceController extends StateNotifier<AsyncValue<void>> {
  final SentencesRepository _repository;
  final Ref _ref; // Ref pozwala nam wchodzić w interakcję z innymi providerami

  AddSentenceController(this._repository, this._ref) 
      : super(const AsyncValue.data(null)); // Stan początkowy: idle (success null)

  Future<bool> addSentence({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // 1. Ustawiamy stan na ładowanie (UI zablokuje przycisk i pokaże spinner)
    state = const AsyncValue.loading();

    try {
      final dto = SentenceCreate(
        originalText: originalText,
        translatedText: translatedText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      await _repository.createSentence(dto);

      // --- ZMIANA ---
      // Zamiast zabijać providera (invalidate), prosimy go o odświeżenie danych.
      // Dzięki temu zachowujemy numer strony.
      await _ref.read(sentencesProvider.notifier).refreshCurrentPage();
      
      // Jeśli wolałbyś skakać do ostatniej strony (bo tam dodał się element),
      // odkomentuj metodę w providerze i użyj tutaj:
      // await _ref.read(sentencesProvider.notifier).goToLastPage();


      // ================= ZMIANA: Zabezpieczenie asynchroniczne =================
      // Jeśli użytkownik zamknął dialog w trakcie wysyłania, kontroler (dzięki .autoDispose)
      // został zniszczony. Nie możemy przypisywać mu nowego stanu.
      if (!mounted) return false;
      // =======================================================================

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      // ================= ZMIANA: PROFESJONALNA OBSŁUGA BŁĘDU =================
      // Zamiast wrzucać do stanu surowy DioException (obiekt 'e'),
      // parsujemy go na przyjazny tekst i wstawiamy jako String.
      final friendlyErrorMessage = ApiErrorHandler.getErrorMessage(e);


      // ================= ZMIANA: Zabezpieczenie asynchroniczne =================
      if (!mounted) return false;
      // =======================================================================

      state = AsyncValue.error(friendlyErrorMessage, stack);
      // =======================================================================
      return false;
    }
  }
}

// ================= ZMIANA: autoDispose =================
// Zmieniamy StateNotifierProvider na StateNotifierProvider.autoDispose
// Dzięki temu, gdy okno dialogowe znika, stan (w tym stary błąd) ulega samozniszczeniu.
final addSentenceControllerProvider = 
    StateNotifierProvider.autoDispose<AddSentenceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sentencesRepositoryProvider);
  return AddSentenceController(repo, ref);
});
// =======================================================