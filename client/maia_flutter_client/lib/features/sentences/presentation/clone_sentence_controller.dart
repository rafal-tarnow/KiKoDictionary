// ================= NOWY PLIK =================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentences_repository.dart';
import 'sentences_provider.dart';
import '../../../core/network/api_error_handler.dart';

class CloneSentenceController extends StateNotifier<AsyncValue<void>> {
  final SentencesRepository _repository;
  final Ref _ref;

  CloneSentenceController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> cloneSentence(int originalSentenceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cloneSentence(originalSentenceId);

      // MAGIA: Odświeżamy w tle listę prywatnych zdań użytkownika!
      // Dzięki temu po przejściu na zakładkę "Moje Zwroty", sklonowane zdanie już tam będzie.
      _ref.read(sentencesProvider.notifier).refreshCurrentPage();

      if (!mounted) return false;
      state = const AsyncValue.data(null);
      return true;
      
    } catch (e, stack) {
      if (!mounted) return false;
      
      // Specjalna obsługa błędu 400 z backendu (własne zdanie)
      // ApiErrorHandler to wyłapie jako standardowy string.
      final friendlyMessage = ApiErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(friendlyMessage, stack);
      return false;
    }
  }
}

final cloneSentenceControllerProvider = 
    StateNotifierProvider.autoDispose<CloneSentenceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sentencesRepositoryProvider);
  return CloneSentenceController(repo, ref);
});