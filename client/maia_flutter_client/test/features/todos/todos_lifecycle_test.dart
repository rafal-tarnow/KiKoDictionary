import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maia_flutter_client/features/todos/data/models/todo_model.dart';
import 'package:maia_flutter_client/features/todos/data/todo_repository.dart';
import 'package:maia_flutter_client/features/todos/presentation/todos_provider.dart';

TodoItem _todo(int id) => TodoItem(
      id: id,
      content: 'Task $id',
      isCompleted: false,
      position: id * 1000.0,
      createdAt: DateTime.utc(2026),
    );

/// Repozytorium, którego odpowiedzi "trzymamy" w Completerach - test decyduje, kiedy wrócą.
class _ControllableTodoRepository extends TodoRepository {
  final List<Completer<List<TodoItem>>> pendingLoads = [];
  Completer<TodoItem>? pendingUpdate;
  int getTodosCalls = 0;

  _ControllableTodoRepository() : super(Dio());

  @override
  Future<List<TodoItem>> getTodos() {
    getTodosCalls++;
    final completer = Completer<List<TodoItem>>();
    pendingLoads.add(completer);
    return completer.future;
  }

  @override
  Future<TodoItem> updateTodo(int id, {String? content, bool? isCompleted}) {
    pendingUpdate = Completer<TodoItem>();
    return pendingUpdate!.future;
  }
}

class _FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  _FakeAuthController({required bool loggedIn})
      : super(AuthState(isAuthenticated: loggedIn, isAppLoading: false));

  void setLoggedIn(bool value) => state = AuthState(isAuthenticated: value, isAppLoading: false);

  @override
  Future<void> checkAuthStatus() async {}

  @override
  void setAuthenticated(bool isAuthenticated) => setLoggedIn(isAuthenticated);

  @override
  Future<void> logout() async => setLoggedIn(false);
}

DioException _unauthorized() {
  final options = RequestOptions(path: '/api/v1/tasks/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 401),
  );
}

void main() {
  group('TodosController po dispose (np. wylogowanie w trakcie zapytania)', () {
    test('udana odpowiedź po dispose nie rzuca wyjątku', () async {
      final repo = _ControllableTodoRepository();
      final controller = TodosController(repo);

      controller.dispose();
      repo.pendingLoads.single.complete([_todo(1)]);

      await expectLater(Future<void>.delayed(Duration.zero), completes);
    });

    test('błąd (np. 401) po dispose nie rzuca wyjątku', () async {
      final repo = _ControllableTodoRepository();
      final controller = TodosController(repo);

      controller.dispose();
      repo.pendingLoads.single.completeError(_unauthorized());

      await expectLater(Future<void>.delayed(Duration.zero), completes);
    });

    test('rollback po nieudanym zapisie i dispose nie rzuca wyjątku', () async {
      final repo = _ControllableTodoRepository();
      final controller = TodosController(repo);
      repo.pendingLoads.single.complete([_todo(1)]);
      await Future<void>.delayed(Duration.zero);

      final toggle = controller.toggleCompleted(controller.state.items.single);
      controller.dispose();
      repo.pendingUpdate!.completeError(_unauthorized());

      await expectLater(toggle, completes);
    });
  });

  group('todosProvider a sesja użytkownika', () {
    late _ControllableTodoRepository repo;
    late _FakeAuthController auth;
    late ProviderContainer container;

    void createContainer({required bool loggedIn}) {
      repo = _ControllableTodoRepository();
      auth = _FakeAuthController(loggedIn: loggedIn);
      container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        todoRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(todosProvider, (_, _) {});
    }

    test('gość nie wysyła zapytań do API', () {
      createContainer(loggedIn: false);

      expect(repo.getTodosCalls, 0);
      expect(container.read(todosProvider).items, isEmpty);
    });

    test('po zalogowaniu zadania ładują się same, po wylogowaniu znikają', () async {
      createContainer(loggedIn: false);

      auth.setLoggedIn(true);
      container.read(todosProvider); // przebudowa providera po zmianie sesji
      expect(repo.getTodosCalls, 1);
      repo.pendingLoads.single.complete([_todo(1), _todo(2)]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(todosProvider).items, hasLength(2));

      auth.setLoggedIn(false);
      expect(container.read(todosProvider).items, isEmpty);
      expect(repo.getTodosCalls, 1); // wylogowanie nie wysyła kolejnych zapytań
    });

    test('wylogowanie w trakcie ładowania nie rzuca wyjątku', () async {
      createContainer(loggedIn: true);

      auth.setLoggedIn(false);
      container.read(todosProvider);
      repo.pendingLoads.single.completeError(_unauthorized());

      await expectLater(Future<void>.delayed(Duration.zero), completes);
      expect(container.read(todosProvider).items, isEmpty);
    });
  });
}
