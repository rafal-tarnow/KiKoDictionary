import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/models/todo_model.dart';
import '../data/todo_repository.dart';

class TodosState {
  final bool isLoading;
  final String? error;
  final List<TodoItem> items;

  TodosState({this.isLoading = false, this.error, this.items = const []});

  TodosState copyWith({bool? isLoading, String? error, List<TodoItem>? items}) {
    return TodosState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // celowo bez fallbacku
      items: items ?? this.items,
    );
  }
}

// Każda metoda po `await` sprawdza `mounted`: kontroler mógł zostać w międzyczasie zniszczony
// (np. wylogowanie albo zmiana sesji w trakcie zapytania). Zapis do `state` po dispose
// kończy się wyjątkiem "Tried to use TodosController after `dispose` was called".
class TodosController extends StateNotifier<TodosState> {
  final TodoRepository _repo;

  /// [autoLoad] = false dla niezalogowanego użytkownika - wtedy nie pytamy API
  /// (bez tokena serwer odpowiada 401, co wymuszałoby kolejne wylogowania).
  TodosController(this._repo, {bool autoLoad = true}) : super(TodosState()) {
    if (autoLoad) loadTodos();
  }

  Future<void> loadTodos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final todos = await _repo.getTodos();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, items: todos);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<bool> addTodo(String content) async {
    try {
      final newTodo = await _repo.createTodo(content);
      if (!mounted) return false;
      // Dodajemy na sam dół listy
      state = state.copyWith(items: [...state.items, newTodo]);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: ApiErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  Future<void> toggleCompleted(TodoItem todo) async {
    // 1. Optymistyczna zmiana UI
    final previousState = state.items;
    final updatedItem = todo.copyWith(isCompleted: !todo.isCompleted);

    state = state.copyWith(
      items: state.items.map((e) => e.id == todo.id ? updatedItem : e).toList(),
    );

    // 2. Zapytanie do API
    try {
      await _repo.updateTodo(todo.id, isCompleted: updatedItem.isCompleted);
    } catch (e) {
      // 3. Rollback w razie błędu sieci
      if (!mounted) return;
      state = state.copyWith(items: previousState, error: "Failed to update task.");
    }
  }

  Future<bool> updateContent(int id, String newContent) async {
    try {
      final updated = await _repo.updateTodo(id, content: newContent);
      if (!mounted) return false;
      state = state.copyWith(
        items: state.items.map((e) => e.id == id ? updated : e).toList(),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: ApiErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  Future<void> deleteTodo(int id) async {
    final previousState = state.items;
    // Optymistyczne usunięcie z UI
    state = state.copyWith(items: state.items.where((e) => e.id != id).toList());

    try {
      await _repo.deleteTodo(id);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(items: previousState, error: "Failed to delete task.");
    }
  }

  // ================= MAGIA DRAG & DROP =================
  // Indeksy z ReorderableListView.onReorderItem (newIndex jest już skorygowany)
  Future<void> reorder(int oldIndex, int newIndex) async {
    // Krok 1: Brak zmiany pozycji / indeks spoza listy
    if (oldIndex == newIndex ||
        oldIndex < 0 || oldIndex >= state.items.length ||
        newIndex < 0 || newIndex >= state.items.length) {
      return;
    }

    // Krok 2: Kopia listy i fizyczne przestawienie elementów lokalnie
    final List<TodoItem> currentList = List.from(state.items);
    final TodoItem itemToMove = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, itemToMove);

    // Krok 3: Optymistyczny update UI, żeby zadanie nie "skakało" przy oczekiwaniu na serwer
    final previousState = state.items;
    state = state.copyWith(items: currentList);

    // Krok 4: Wyznaczenie sąsiadów dla API
    final int? prevId = newIndex > 0 ? currentList[newIndex - 1].id : null;
    final int? nextId = newIndex < currentList.length - 1 ? currentList[newIndex + 1].id : null;

    // Krok 5: Strzał do API
    try {
      final updatedTodo = await _repo.reorderTodo(itemToMove.id, prevId, nextId);
      if (!mounted) return;
      // Podmiana na wersję z serwera (z prawidłowo przeliczonym floatem "position")
      state = state.copyWith(
        items: state.items.map((e) => e.id == itemToMove.id ? updatedTodo : e).toList()
      );
    } catch (e) {
      if (!mounted) return;
      // Rollback w razie braku prądu/internetu
      state = state.copyWith(items: previousState, error: "Reorder failed. Synchronizing...");
      await loadTodos(); // Awaryjne odświeżenie z serwera
    }
  }
}

final todosProvider = StateNotifierProvider<TodosController, TodosState>((ref) {
  // Zmiana sesji (logowanie / wylogowanie) tworzy kontroler od nowa:
  // zalogowany -> pobiera zadania swojego konta, gość -> pusta lista bez zapytań do API.
  final isLoggedIn = ref.watch(authControllerProvider.select((s) => s.isAuthenticated));
  return TodosController(ref.watch(todoRepositoryProvider), autoLoad: isLoggedIn);
});
