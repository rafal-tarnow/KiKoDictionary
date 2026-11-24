import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_model.dart';
import '../data/sentences_repository.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/utils/list_reorder.dart';

class SentencesState {
  final List<Sentence> sentences;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;

  const SentencesState({
    this.sentences = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  bool get isLastPage => currentPage >= totalPages;

  /// Czy zdanie z pozycji [index] bieżącej strony jest pierwsze na całej liście.
  bool isFirstOverall(int index) => currentPage == 1 && index == 0;

  /// Czy zdanie z pozycji [index] bieżącej strony jest ostatnie na całej liście.
  bool isLastOverall(int index) => isLastPage && index == sentences.length - 1;

  SentencesState copyWith({
    List<Sentence>? sentences,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
  }) {
    return SentencesState(
      sentences: sentences ?? this.sentences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class SentencesNotifier extends StateNotifier<SentencesState> {
  final SentencesRepository _repository;
  static const int _perPage = 10;

  SentencesNotifier(this._repository) : super(const SentencesState()) {
    loadSentences(page: 1);
  }

  Future<void> loadSentences({required int page}) async {
    if (state.isLoading) return;

    // Resetujemy błąd przy nowej próbie
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getSentences(
        page: page,
        perPage: _perPage,
      );

      state = state.copyWith(
        isLoading: false,
        sentences: response.sentences,
        totalPages: response.totalPages,
        currentPage: page,
        errorMessage: null, // Sukces = brak błędu
      );
    } catch (e) {
      // TU JEST ZMIANA: Używamy naszego parsera błędów
      final friendlyMessage = ApiErrorHandler.getErrorMessage(e);

      state = state.copyWith(isLoading: false, errorMessage: friendlyMessage);
    }
  }

  // --- NOWA METODA ---
  // Odświeża aktualną stronę bez resetowania stanu do zera
  Future<void> refreshCurrentPage() async {
    // Ładujemy ponownie tę samą stronę, na której jesteśmy
    await loadSentences(page: state.currentPage);
  }

  /* 
  // Opcjonalnie: Jeśli wolałbyś iść na ostatnią stronę po dodaniu:
  Future<void> goToLastPage() async {
     // Najpierw pobierzmy info (może doszła nowa strona?)
     // To uproszczenie, w idealnym świecie API po dodaniu zwraca ID nowej strony
     await loadSentences(page: state.totalPages);
  }
  */

  void nextPage() {
    if (!state.isLastPage) {
      loadSentences(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      loadSentences(page: state.currentPage - 1);
    }
  }

  // Usuwa element z lokalnego stanu (UI odświeży się natychmiast)
  void removeSentenceLocally(int sentenceId) {
    // std::remove_if w C++ style
    final updatedList = state.sentences
        .where((s) => s.id != sentenceId)
        .toList();

    state = state.copyWith(
      sentences: updatedList,
      // Opcjonalnie: można tu obsłużyć zmniejszenie licznika stron itp.
    );
  }

  void updateSentenceLocally(Sentence updatedSentence) {
    // Tworzymy nową listę, mapując starą
    final newSentences = state.sentences.map((s) {
      return s.id == updatedSentence.id ? updatedSentence : s;
    }).toList();

    // Emitujemy nowy stan
    state = state.copyWith(sentences: newSentences);
  }

  void clearData(){
    state = const SentencesState();
  }

  // ================= Kolejność (drag & drop, na początek / na koniec) =================

  /// Przeciągnięcie w obrębie bieżącej strony. Indeksy z `ReorderableListView.onReorderItem`.
  /// Lista zmienia się od razu (optymistycznie); przy błędzie wraca do poprzedniej kolejności.
  Future<bool> reorder(int oldIndex, int newIndex) async {
    final result = reorderList(state.sentences, oldIndex, newIndex);
    if (result == null) return true;

    final previous = state.sentences;
    state = state.copyWith(sentences: result.items);

    try {
      final updated = await _repository.reorderSentence(
        result.moved.id,
        previousId: result.previous?.id,
        nextId: result.next?.id,
      );
      updateSentenceLocally(updated);
      return true;
    } catch (e) {
      state = state.copyWith(sentences: previous, errorMessage: ApiErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  /// Na sam początek listy (góra strony 1) - także ze stron dalszych niż pierwsza.
  Future<bool> moveToTop(int sentenceId) =>
      _moveAndReload(() => _repository.moveSentenceToTop(sentenceId));

  /// Na sam koniec listy (dół ostatniej strony).
  Future<bool> moveToBottom(int sentenceId) =>
      _moveAndReload(() => _repository.moveSentenceToBottom(sentenceId));

  Future<bool> _moveAndReload(Future<Sentence> Function() move) async {
    try {
      await move();
    } catch (e) {
      state = state.copyWith(errorMessage: ApiErrorHandler.getErrorMessage(e));
      return false;
    }
    // Zdanie mogło opuścić bieżącą stronę (a inne na nią wejść) - pobieramy ją od nowa
    await refreshCurrentPage();
    return true;
  }
}

final sentencesProvider =
    StateNotifierProvider<SentencesNotifier, SentencesState>((ref) {
      final repository = ref.watch(sentencesRepositoryProvider);
      return SentencesNotifier(repository);
    });
