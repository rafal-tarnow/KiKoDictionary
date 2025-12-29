import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_model.dart';
import '../data/sentences_repository.dart';

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

    // Tu mała zmiana: zachowujemy stare zdania podczas ładowania (lepszy UX),
    // chyba że chcesz, żeby znikały i pojawiał się spinner.
    // Obecnie ustawiasz isLoading: true, co w UI wyświetla spinner zamiast listy.
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
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
}

final sentencesProvider =
    StateNotifierProvider<SentencesNotifier, SentencesState>((ref) {
      final repository = ref.watch(sentencesRepositoryProvider);
      return SentencesNotifier(repository);
    });
