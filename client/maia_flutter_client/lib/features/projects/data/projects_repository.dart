import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/project.dart';
import 'projects_dio_provider.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(projectsDioProvider));
});

/// Dostęp do `/api/v1/projects`. Błędy (DioException) lecą wyżej -
/// kontrolery tłumaczą je przez `ApiErrorHandler`.
class ProjectsRepository {
  static const _basePath = '/api/v1/projects';

  final Dio _dio;

  ProjectsRepository(this._dio);

  Future<List<Project>> getProjects() async {
    final response = await _dio.get<List<dynamic>>(_basePath);
    return response.data!
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Project> createProject(ProjectDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(_basePath, data: draft.toJson());
    return Project.fromJson(response.data!);
  }

  Future<Project> updateProject(int projectId, ProjectDraft draft) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_basePath/$projectId',
      data: draft.toJson(),
    );
    return Project.fromJson(response.data!);
  }

  Future<void> deleteProject(int projectId) async {
    await _dio.delete<void>('$_basePath/$projectId');
  }

  /// [previousId] - projekt nad nową pozycją, [nextId] - projekt pod nią.
  Future<Project> reorderProject(int projectId, {int? previousId, int? nextId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_basePath/$projectId/reorder',
      data: {'prev_id': previousId, 'next_id': nextId},
    );
    return Project.fromJson(response.data!);
  }
}
