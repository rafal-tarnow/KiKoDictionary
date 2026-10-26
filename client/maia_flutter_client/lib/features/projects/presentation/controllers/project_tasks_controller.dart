import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../data/models/project_task.dart';
import '../../data/project_tasks_repository.dart';
import '../../domain/action_result.dart';
import '../../domain/list_reorder.dart';
import 'projects_controller.dart';
import 'projects_session_provider.dart';

class ProjectTasksState extends Equatable {
  final List<ProjectTask> tasks;
  final bool isLoading;

  /// Błąd ładowania listy (pokazywany jako pasek z przyciskiem "Retry").
  final String? errorMessage;

  const ProjectTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get completedCount => tasks.where((task) => task.isCompleted).length;

  ProjectTasksState copyWith({List<ProjectTask>? tasks, bool? isLoading, String? errorMessage}) {
    return ProjectTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // celowo bez fallbacku - każda zmiana stanu czyści błąd
    );
  }

  @override
  List<Object?> get props => [tasks, isLoading, errorMessage];
}

/// Zadania jednego projektu. `family` -> osobny stan per projekt,
/// `autoDispose` -> stan jest zwalniany po wyjściu z projektu.
class ProjectTasksController extends AutoDisposeFamilyNotifier<ProjectTasksState, int> {
  int _session = 0;

  int get _projectId => arg;

  ProjectTasksRepository get _repository => ref.read(projectTasksRepositoryProvider);

  @override
  ProjectTasksState build(int projectId) {
    _session++;
    // Po wyjściu z projektu (autoDispose) spóźnione odpowiedzi API są ignorowane
    ref.onDispose(() => _session++);
    final isAuthenticated = ref.watch(projectsSessionProvider);
    if (!isAuthenticated) return const ProjectTasksState();

    Future.microtask(loadTasks);
    return const ProjectTasksState(isLoading: true);
  }

  Future<void> loadTasks() async {
    final session = _session;
    state = state.copyWith(isLoading: true);
    try {
      final tasks = await _repository.getTasks(_projectId);
      if (session != _session) return;
      _setTasks(tasks);
    } catch (e) {
      if (session != _session) return;
      state = state.copyWith(isLoading: false, errorMessage: ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> createTask(TaskDraft draft) async {
    final session = _session;
    try {
      final created = await _repository.createTask(_projectId, draft);
      if (session == _session) _setTasks([...state.tasks, created]);
      return const ActionSuccess();
    } catch (e) {
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> updateTask(int taskId, TaskDraft draft) async {
    final session = _session;
    try {
      final updated = await _repository.updateTask(_projectId, taskId, draft);
      if (session == _session) _replace(updated);
      return const ActionSuccess();
    } catch (e) {
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> toggleCompleted(ProjectTask task) async {
    final session = _session;
    final previous = state.tasks;
    // Optymistycznie: checkbox reaguje natychmiast
    _replace(task.copyWith(isCompleted: !task.isCompleted));
    try {
      final updated = await _repository.setCompleted(
        _projectId,
        task.id,
        isCompleted: !task.isCompleted,
      );
      if (session == _session) _replace(updated);
      return const ActionSuccess();
    } catch (e) {
      if (session == _session) _setTasks(previous);
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> deleteTask(int taskId) async {
    final session = _session;
    final previous = state.tasks;
    _setTasks(previous.where((task) => task.id != taskId).toList());
    try {
      await _repository.deleteTask(_projectId, taskId);
      return const ActionSuccess();
    } catch (e) {
      if (session == _session) _setTasks(previous);
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  /// Indeksy z `ReorderableListView.onReorderItem`.
  Future<ActionResult> reorderTasks(int oldIndex, int newIndex) async {
    final result = reorderList(state.tasks, oldIndex, newIndex);
    if (result == null) return const ActionSuccess();

    final session = _session;
    final previous = state.tasks;
    _setTasks(result.items);

    try {
      final updated = await _repository.reorderTask(
        _projectId,
        result.moved.id,
        previousId: result.previous?.id,
        nextId: result.next?.id,
      );
      if (session == _session) _replace(updated);
      return const ActionSuccess();
    } catch (e) {
      if (session != _session) return const ActionSuccess();
      _setTasks(previous);
      await loadTasks(); // Synchronizacja z serwerem po nieudanej operacji
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  void _replace(ProjectTask updated) {
    _setTasks([for (final task in state.tasks) task.id == updated.id ? updated : task]);
  }

  /// Każda zmiana listy aktualizuje też liczniki na karcie projektu.
  void _setTasks(List<ProjectTask> tasks) {
    state = state.copyWith(tasks: tasks, isLoading: false);
    ref.read(projectsControllerProvider.notifier).syncTaskStats(
          _projectId,
          total: tasks.length,
          completed: state.completedCount,
        );
  }
}

final projectTasksControllerProvider = NotifierProvider.autoDispose
    .family<ProjectTasksController, ProjectTasksState, int>(ProjectTasksController.new);
