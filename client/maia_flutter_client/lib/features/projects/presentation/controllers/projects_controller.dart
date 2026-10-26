import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../data/models/project.dart';
import '../../data/projects_repository.dart';
import '../../domain/action_result.dart';
import '../../domain/list_reorder.dart';
import 'projects_session_provider.dart';

class ProjectsState extends Equatable {
  final List<Project> projects;
  final bool isLoading;

  /// Błąd ładowania listy (pokazywany jako pasek z przyciskiem "Retry").
  final String? errorMessage;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  Project? findById(int id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  ProjectsState copyWith({List<Project>? projects, bool? isLoading, String? errorMessage}) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // celowo bez fallbacku - każda zmiana stanu czyści błąd
    );
  }

  @override
  List<Object?> get props => [projects, isLoading, errorMessage];
}

class ProjectsController extends Notifier<ProjectsState> {
  /// Zwiększany przy każdej zmianie sesji. Odpowiedź, która przyjdzie po
  /// wylogowaniu (lub zalogowaniu innego usera), jest ignorowana.
  int _session = 0;

  ProjectsRepository get _repository => ref.read(projectsRepositoryProvider);

  @override
  ProjectsState build() {
    _session++;
    final isAuthenticated = ref.watch(projectsSessionProvider);
    if (!isAuthenticated) return const ProjectsState();

    Future.microtask(loadProjects);
    return const ProjectsState(isLoading: true);
  }

  Future<void> loadProjects() async {
    final session = _session;
    state = state.copyWith(isLoading: true);
    try {
      final projects = await _repository.getProjects();
      if (session != _session) return;
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      if (session != _session) return;
      state = state.copyWith(isLoading: false, errorMessage: ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> createProject(ProjectDraft draft) async {
    final session = _session;
    try {
      final created = await _repository.createProject(draft);
      if (session == _session) {
        state = state.copyWith(projects: [...state.projects, created]);
      }
      return const ActionSuccess();
    } catch (e) {
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> updateProject(int projectId, ProjectDraft draft) async {
    final session = _session;
    try {
      final updated = await _repository.updateProject(projectId, draft);
      if (session == _session) _replace(updated);
      return const ActionSuccess();
    } catch (e) {
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  Future<ActionResult> deleteProject(int projectId) async {
    final session = _session;
    final previous = state.projects;
    // Optymistycznie: znika od razu, w razie błędu wraca na miejsce
    state = state.copyWith(projects: previous.where((p) => p.id != projectId).toList());
    try {
      await _repository.deleteProject(projectId);
      return const ActionSuccess();
    } catch (e) {
      if (session == _session) state = state.copyWith(projects: previous);
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  /// Indeksy z `ReorderableListView.onReorderItem`.
  Future<ActionResult> reorderProjects(int oldIndex, int newIndex) async {
    final result = reorderList(state.projects, oldIndex, newIndex);
    if (result == null) return const ActionSuccess();

    final session = _session;
    final previous = state.projects;
    state = state.copyWith(projects: result.items); // UI nie "skacze" w oczekiwaniu na serwer

    try {
      final updated = await _repository.reorderProject(
        result.moved.id,
        previousId: result.previous?.id,
        nextId: result.next?.id,
      );
      if (session == _session) _replace(updated);
      return const ActionSuccess();
    } catch (e) {
      if (session != _session) return const ActionSuccess();
      state = state.copyWith(projects: previous);
      await loadProjects(); // Synchronizacja z serwerem po nieudanej operacji
      return ActionFailure(ApiErrorHandler.getErrorMessage(e));
    }
  }

  /// Wywoływane przez kontroler zadań - liczniki na kartach projektów
  /// są aktualne bez ponownego pobierania listy.
  void syncTaskStats(int projectId, {required int total, required int completed}) {
    final project = state.findById(projectId);
    if (project == null) return;
    if (project.taskCount == total && project.completedTaskCount == completed) return;
    _replace(project.copyWith(taskCount: total, completedTaskCount: completed));
  }

  void _replace(Project updated) {
    state = state.copyWith(
      projects: [
        for (final project in state.projects) project.id == updated.id ? updated : project,
      ],
    );
  }
}

final projectsControllerProvider = NotifierProvider<ProjectsController, ProjectsState>(
  ProjectsController.new,
);
