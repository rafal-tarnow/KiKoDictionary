import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maia_flutter_client/features/todos/data/models/todo_model.dart';
import 'package:maia_flutter_client/features/todos/data/todo_repository.dart';
import 'package:maia_flutter_client/features/todos/presentation/todos_page.dart';
import 'package:maia_flutter_client/features/todos/presentation/todos_provider.dart';

TodoItem _todo(int id) => TodoItem(
      id: id,
      content: 'Task $id',
      isCompleted: false,
      position: id * 1000.0,
      createdAt: DateTime.utc(2026),
    );

class _FakeTodoRepository extends TodoRepository {
  final List<TodoItem> items;
  final List<({int id, int? prevId, int? nextId})> reorderCalls = [];

  _FakeTodoRepository(this.items) : super(Dio());

  @override
  Future<List<TodoItem>> getTodos() async => List.of(items);

  @override
  Future<TodoItem> reorderTodo(int id, int? prevId, int? nextId) async {
    reorderCalls.add((id: id, prevId: prevId, nextId: nextId));
    return items.firstWhere((t) => t.id == id);
  }
}

/// Zalogowany użytkownik bez prawdziwego storage / sieci.
class _LoggedInAuthController extends StateNotifier<AuthState> implements AuthController {
  _LoggedInAuthController() : super(const AuthState(isAuthenticated: true, isAppLoading: false));

  @override
  Future<void> checkAuthStatus() async {}

  @override
  void setAuthenticated(bool isAuthenticated) {}

  @override
  Future<void> logout() async {}
}

List<String> _visibleTitles(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.textContaining('Task ')).toList();
  final positioned = [
    for (final text in texts) (text.data!, tester.getTopLeft(find.byWidget(text)).dy),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return positioned.map((e) => e.$1).toList();
}

void main() {
  group('TodosController.reorder (indeksy z onReorderItem)', () {
    late _FakeTodoRepository repo;
    late TodosController controller;

    setUp(() async {
      repo = _FakeTodoRepository([_todo(1), _todo(2), _todo(3)]);
      controller = TodosController(repo);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => controller.dispose());

    test('przeniesienie w dół na koniec', () async {
      await controller.reorder(0, 2);

      expect(controller.state.items.map((t) => t.id), [2, 3, 1]);
      expect(repo.reorderCalls.single, (id: 1, prevId: 3, nextId: null));
    });

    test('przeniesienie w górę na początek', () async {
      await controller.reorder(2, 0);

      expect(controller.state.items.map((t) => t.id), [3, 1, 2]);
      expect(repo.reorderCalls.single, (id: 3, prevId: null, nextId: 1));
    });

    test('ta sama pozycja lub zły indeks - bez zapytania do API', () async {
      await controller.reorder(1, 1);
      await controller.reorder(0, 5);

      expect(controller.state.items.map((t) => t.id), [1, 2, 3]);
      expect(repo.reorderCalls, isEmpty);
    });
  });

  group('TodosPage - przeciąganie kafelków', () {
    late _FakeTodoRepository repo;

    Future<void> pumpPage(WidgetTester tester) async {
      repo = _FakeTodoRepository([_todo(1), _todo(2), _todo(3)]);
      tester.view.physicalSize = const Size(400 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => _LoggedInAuthController()),
            todoRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: TodosPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('uchwyt jest tylko po lewej stronie kafelka (bez domyślnego uchwytu Fluttera)', (tester) async {
      await pumpPage(tester);

      final handle = tester.getCenter(find.byIcon(Icons.drag_indicator).first);
      final title = tester.getTopLeft(find.text('Task 1'));
      expect(handle.dx, lessThan(title.dx));
      // Domyślny uchwyt desktopowy Fluttera (po prawej) nie może się pojawić
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('przeciągnięcie za lewy uchwyt przenosi zadanie', (tester) async {
      await pumpPage(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_indicator).first),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_visibleTitles(tester), ['Task 2', 'Task 3', 'Task 1']);
      expect(repo.reorderCalls.single.id, 1);
    });

    testWidgets('długie przytrzymanie kafelka (dotyk) też pozwala przeciągnąć', (tester) async {
      await pumpPage(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Task 3')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -25));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_visibleTitles(tester), ['Task 3', 'Task 1', 'Task 2']);
      expect(repo.reorderCalls.single, (id: 3, prevId: null, nextId: 1));
    });
  });
}
