import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/project_task.dart';
import 'projects_dio_provider.dart';

final projectTasksRepositoryProvider = Provider<ProjectTasksRepository>((ref) {
  return ProjectTasksRepository(ref.watch(projectsDioProvider));
});

/// Dostęp do `/api/v1/projects/{projectId}/tasks`.
class ProjectTasksRepository {
  final Dio _dio;

  ProjectTasksRepository(this._dio);

  String _tasksPath(int projectId) => '/api/v1/projects/$projectId/tasks';

  Future<List<ProjectTask>> getTasks(int projectId) async {
    final response = await _dio.get<List<dynamic>>(_tasksPath(projectId));
    return response.data!
        .map((json) => ProjectTask.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectTask> createTask(int projectId, TaskDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _tasksPath(projectId),
      data: draft.toJson(),
    );
    return ProjectTask.fromJson(response.data!);
  }

  Future<ProjectTask> updateTask(int projectId, int taskId, TaskDraft draft) {
    return _patch(projectId, taskId, draft.toJson());
  }

  Future<ProjectTask> setCompleted(int projectId, int taskId, {required bool isCompleted}) {
    return _patch(projectId, taskId, {'is_completed': isCompleted});
  }

  Future<void> deleteTask(int projectId, int taskId) async {
    await _dio.delete<void>('${_tasksPath(projectId)}/$taskId');
  }

  /// [previousId] - zadanie nad nową pozycją, [nextId] - zadanie pod nią.
  Future<ProjectTask> reorderTask(int projectId, int taskId, {int? previousId, int? nextId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_tasksPath(projectId)}/$taskId/reorder',
      data: {'prev_id': previousId, 'next_id': nextId},
    );
    return ProjectTask.fromJson(response.data!);
  }

  Future<ProjectTask> _patch(int projectId, int taskId, Map<String, dynamic> data) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${_tasksPath(projectId)}/$taskId',
      data: data,
    );
    return ProjectTask.fromJson(response.data!);
  }
}
