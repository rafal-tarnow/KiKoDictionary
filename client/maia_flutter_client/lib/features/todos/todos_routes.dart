import 'package:go_router/go_router.dart';
import 'presentation/todos_page.dart';

/// Trasy modułu Daily Tasks.
abstract final class TodosRoutes {
  static const todos = 'todos';
  static const todosPath = '/todos';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: todosPath, name: todos, builder: (context, state) => const TodosPage())],
      );
}
