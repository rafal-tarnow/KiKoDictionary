import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_update_model.dart';
import '../data/sentences_repository.dart';
import 'sentences_provider.dart';

// Używamy StateNotifier do zarządzania stanem asynchronicznym (loading/error/data)
// AsyncValue<void> informuje UI czy trwa zapisywanie.
class EditSentenceController extends StateNotifier<AsyncValue<void>> {
  final SentencesRepository _repository;
  final Ref _ref;

  EditSentenceController(this._repository, this._ref) 
      : super(const AsyncValue.data(null));

  Future<bool> editSentence({
    required int id,
    required String sentence,
    required String language,
    required String translation,
  }) async {
    state = const AsyncValue.loading(); // Pokaż spinner

    try {
      final dto = SentenceUpdate(
        sentence: sentence,
        language: language,
        translation: translation,
      );

      // 1. Wywołanie API
      final updatedSentence = await _repository.updateSentence(id: id, data: dto);

      // 2. Aktualizacja lokalnego stanu listy (nie musimy odświeżać całej strony!)
      _ref.read(sentencesProvider.notifier).updateSentenceLocally(updatedSentence);

      state = const AsyncValue.data(null); // Sukces
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack); // Błąd
      return false;
    }
  }
}

final editSentenceControllerProvider = 
    StateNotifierProvider<EditSentenceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sentencesRepositoryProvider);
  return EditSentenceController(repo, ref);
});