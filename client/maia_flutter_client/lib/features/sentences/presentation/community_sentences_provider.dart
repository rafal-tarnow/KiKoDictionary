// ================= NOWY PLIK =================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_model.dart';
import '../data/sentences_repository.dart';
import '../../../core/network/api_error_handler.dart';
import '../../user/presentation/controllers/user_controller.dart';

class CommunitySentencesState {
  final List<Sentence> sentences;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  // Filtry językowe
  final String? sourceLang;
  final String? targetLang;

  const CommunitySentencesState({
    this.sentences = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.sourceLang,
    this.targetLang,
  });

  bool get isLastPage => currentPage >= totalPages;

  CommunitySentencesState copyWith({
    List<Sentence>? sentences,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    String? sourceLang,
    String? targetLang,
  }) {
    // Uwaga na hack z usuwaniem filtra: jeśli chcesz wyczyścić filtr, wyślij np. pusty string, 
    // który na backendzie zostanie zignorowany. Tu dla uproszczenia zawsze podmieniamy.
    return CommunitySentencesState(
      sentences: sentences ?? this.sentences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
    );
  }
}

class CommunitySentencesNotifier extends StateNotifier<CommunitySentencesState> {
  final SentencesRepository _repository;
  final Ref _ref;
  static const int _perPage = 10;

  CommunitySentencesNotifier(this._repository, this._ref) : super(const CommunitySentencesState()) {
    // Od razu przy tworzeniu providera odpalamy ładowanie
    _initFiltersAndLoad();
  }

  // Funkcja wyciąga język usera jako domyślny język źródłowy
  void _initFiltersAndLoad() {
    final user = _ref.read(userControllerProvider).valueOrNull;
    final defaultSourceLang = user?.profile?.nativeLanguage;
    // Ustawiamy filtr i ładujemy
    state = state.copyWith(sourceLang: defaultSourceLang);
    loadSentences(page: 1);
  }

  Future<void> loadSentences({required int page}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getCommunitySentences(
        page: page,
        perPage: _perPage,
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
      );

      state = state.copyWith(
        isLoading: false,
        sentences: response.sentences,
        totalPages: response.totalPages,
        currentPage: page,
        errorMessage: null,
      );
    } catch (e) {
      final friendlyMessage = ApiErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMessage);
    }
  }

  // Zmiana filtrów resetuje paginację do strony 1
  void updateFilters({String? sourceLang, String? targetLang}) {
    state = CommunitySentencesState(
      sourceLang: sourceLang ?? state.sourceLang,
      targetLang: targetLang ?? state.targetLang,
    ); // Reset state, ale trzymamy filtry
    loadSentences(page: 1);
  }

  void refreshCurrentPage() {
    loadSentences(page: state.currentPage);
  }

  void nextPage() {
    if (!state.isLastPage) loadSentences(page: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) loadSentences(page: state.currentPage - 1);
  }
}

final communitySentencesProvider =
    StateNotifierProvider<CommunitySentencesNotifier, CommunitySentencesState>((ref) {
  final repository = ref.watch(sentencesRepositoryProvider);
  return CommunitySentencesNotifier(repository, ref);
});