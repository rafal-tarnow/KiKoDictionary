import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/todo_model.dart';
import 'todo_dio_provider.dart';

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final dio = ref.watch(todoDioProvider);
  return TodoRepository(dio);
});

class TodoRepository {
  final Dio _dio;
  TodoRepository(this._dio);

  Future<List<TodoItem>> getTodos() async {
    try {
      final response = await _dio.get('/api/v1/tasks/');
      final list = response.data as List;
      return list.map((e) => TodoItem.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TodoItem> createTodo(String content) async {
    try {
      final response = await _dio.post('/api/v1/tasks/', data: {'content': content});
      return TodoItem.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TodoItem> updateTodo(int id, {String? content, bool? isCompleted}) async {
    try {
      final data = <String, dynamic>{};
      if (content != null) data['content'] = content;
      if (isCompleted != null) data['is_completed'] = isCompleted;

      final response = await _dio.put('/api/v1/tasks/$id', data: data);
      return TodoItem.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _dio.delete('/api/v1/tasks/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<TodoItem> reorderTodo(int id, int? prevId, int? nextId) async {
    try {
      final response = await _dio.post(
        '/api/v1/tasks/$id/reorder',
        data: {
          'prev_task_id': prevId,
          'next_task_id': nextId,
        },
      );
      return TodoItem.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}