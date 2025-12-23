import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_create_model.dart';
import '../data/sentences_repository.dart';
import 'sentences_provider.dart'; // Potrzebne, żeby odświeżyć listę po sukcesie

// Controller zarządza stanem operacji dodawania.
// AsyncValue<void> oznacza, że operacja nie zwraca wartości, ale śledzimy jej status.
class AddSentenceController extends StateNotifier<AsyncValue<void>> {
  final SentencesRepository _repository;
  final Ref _ref; // Ref pozwala nam wchodzić w interakcję z innymi providerami

  AddSentenceController(this._repository, this._ref) 
      : super(const AsyncValue.data(null)); // Stan początkowy: idle (success null)

  Future<bool> addSentence({
    required String sentence,
    required String language,
    required String translation,
  }) async {
    // 1. Ustawiamy stan na ładowanie (UI zablokuje przycisk i pokaże spinner)
    state = const AsyncValue.loading();

    try {
      final dto = SentenceCreate(
        sentence: sentence,
        language: language,
        translation: translation,
      );

      await _repository.createSentence(dto);

      // --- ZMIANA ---
      // Zamiast zabijać providera (invalidate), prosimy go o odświeżenie danych.
      // Dzięki temu zachowujemy numer strony.
      await _ref.read(sentencesProvider.notifier).refreshCurrentPage();
      
      // Jeśli wolałbyś skakać do ostatniej strony (bo tam dodał się element),
      // odkomentuj metodę w providerze i użyj tutaj:
      // await _ref.read(sentencesProvider.notifier).goToLastPage();

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      // 4. Błąd
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Rejestracja providera
final addSentenceControllerProvider = 
    StateNotifierProvider<AddSentenceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sentencesRepositoryProvider);
  return AddSentenceController(repo, ref);
});