import 'package:dio/dio.dart';
import 'package:maia_flutter_client/features/projects/data/models/project.dart';
import 'package:maia_flutter_client/features/projects/data/models/project_task.dart';
import 'package:maia_flutter_client/features/projects/data/models/task_priority.dart';
import 'package:maia_flutter_client/features/projects/data/project_tasks_repository.dart';
import 'package:maia_flutter_client/features/projects/data/projects_repository.dart';

final _createdAt = DateTime.utc(2026, 1, 1);

Project buildProject(int id, {String? name, int tasks = 0, int completed = 0, double? position}) {
  return Project(
    id: id,
    name: name ?? 'Project $id',
    description: null,
    color: '#673AB7',
    position: position ?? id * 1000.0,
    taskCount: tasks,
    completedTaskCount: completed,
    createdAt: _createdAt,
    updatedAt: _createdAt,
  );
}

ProjectTask buildTask(int id, {int projectId = 1, bool isCompleted = false, double? position}) {
  return ProjectTask(
    id: id,
    projectId: projectId,
    title: 'Task $id',
    description: null,
    priority: TaskPriority.none,
    dueDate: null,
    isCompleted: isCompleted,
    completedAt: null,
    position: position ?? id * 1000.0,
    createdAt: _createdAt,
    updatedAt: _createdAt,
  );
}

DioException serverError() {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 500, data: {'detail': 'Boom'}),
  );
}

/// Repozytorium w pamięci - zapisuje wywołania, opcjonalnie rzuca błąd.
class FakeProjectsRepository implements ProjectsRepository {
  List<Project> projects;
  bool shouldFail = false;
  final List<({int id, int? previousId, int? nextId})> reorderCalls = [];

  FakeProjectsRepository(this.projects);

  void _maybeFail() {
    if (shouldFail) throw serverError();
  }

  @override
  Future<List<Project>> getProjects() async {
    _maybeFail();
    return List.of(projects);
  }

  @override
  Future<Project> createProject(ProjectDraft draft) async {
    _maybeFail();
    final project = buildProject(projects.length + 100, name: draft.name);
    projects = [...projects, project];
    return project;
  }

  @override
  Future<Project> updateProject(int projectId, ProjectDraft draft) async {
    _maybeFail();
    return projects.firstWhere((p) => p.id == projectId).copyWith(name: draft.name);
  }

  @override
  Future<void> deleteProject(int projectId) async {
    _maybeFail();
    projects = projects.where((p) => p.id != projectId).toList();
  }

  @override
  Future<Project> reorderProject(int projectId, {int? previousId, int? nextId}) async {
    reorderCalls.add((id: projectId, previousId: previousId, nextId: nextId));
    _maybeFail();
    return projects.firstWhere((p) => p.id == projectId).copyWith(position: 1500);
  }
}

class FakeProjectTasksRepository implements ProjectTasksRepository {
  List<ProjectTask> tasks;
  bool shouldFail = false;

  FakeProjectTasksRepository(this.tasks);

  void _maybeFail() {
    if (shouldFail) throw serverError();
  }

  @override
  Future<List<ProjectTask>> getTasks(int projectId) async {
    _maybeFail();
    return tasks.where((t) => t.projectId == projectId).toList();
  }

  @override
  Future<ProjectTask> createTask(int projectId, TaskDraft draft) async {
    _maybeFail();
    final task = buildTask(tasks.length + 100, projectId: projectId);
    tasks = [...tasks, task];
    return task;
  }

  @override
  Future<ProjectTask> updateTask(int projectId, int taskId, TaskDraft draft) async {
    _maybeFail();
    return tasks.firstWhere((t) => t.id == taskId);
  }

  @override
  Future<ProjectTask> setCompleted(int projectId, int taskId, {required bool isCompleted}) async {
    _maybeFail();
    return tasks.firstWhere((t) => t.id == taskId).copyWith(isCompleted: isCompleted);
  }

  @override
  Future<void> deleteTask(int projectId, int taskId) async {
    _maybeFail();
    tasks = tasks.where((t) => t.id != taskId).toList();
  }

  @override
  Future<ProjectTask> reorderTask(int projectId, int taskId, {int? previousId, int? nextId}) async {
    _maybeFail();
    return tasks.firstWhere((t) => t.id == taskId);
  }
}
