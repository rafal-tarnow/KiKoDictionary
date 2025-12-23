import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_model.dart';
import '../data/sentences_repository.dart';

class SentencesState {
  final List<Sentence> sentences;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages; // Nowe pole: całkowita liczba stron

  const SentencesState({
    this.sentences = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1, // Domyślnie 1
  });

  // Getter (computed property) - czy jesteśmy na ostatniej stronie?
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
  static const int _perPage = 10; // Zmieniłem na 10 zgodnie z Twoim JSONem

  SentencesNotifier(this._repository) : super(const SentencesState()) {
    loadSentences(page: 1);
  }

  Future<void> loadSentences({required int page}) async {
    if (state.isLoading) return;

    // Resetujemy błąd i ustawiamy loading
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Pobieramy naszą strukturę z repozytorium
      final response = await _repository.getSentences(page: page, perPage: _perPage);

      state = state.copyWith(
        isLoading: false,
        sentences: response.sentences, // Lista zdań
        totalPages: response.totalPages, // Całkowita liczba stron z API
        currentPage: page,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void nextPage() {
    // Używamy gettera isLastPage, który teraz bazuje na total_pages z API
    if (!state.isLastPage) {
      loadSentences(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      loadSentences(page: state.currentPage - 1);
    }
  }
}

final sentencesProvider = StateNotifierProvider<SentencesNotifier, SentencesState>((ref) {
  final repository = ref.watch(sentencesRepositoryProvider);
  return SentencesNotifier(repository);
});