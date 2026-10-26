import 'package:equatable/equatable.dart';
import 'task_priority.dart';

class ProjectTask extends Equatable {
  final int id;
  final int projectId;
  final String title;
  final String? description;
  final TaskPriority priority;

  /// Sama data (bez godziny), czas lokalny.
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final double position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    required this.completedAt,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    final dueDate = json['due_date'] as String?;
    final completedAt = json['completed_at'] as String?;
    return ProjectTask(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromApi(json['priority'] as String?),
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      isCompleted: json['is_completed'] as bool,
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      position: (json['position'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Zadanie po terminie = niewykonane i termin minął (dzisiaj jeszcze nie jest po terminie).
  bool isOverdue(DateTime now) {
    if (isCompleted || dueDate == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  ProjectTask copyWith({bool? isCompleted}) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt,
      position: position,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        priority,
        dueDate,
        isCompleted,
        completedAt,
        position,
        createdAt,
        updatedAt,
      ];
}

/// Dane z formularza zadania (tworzenie i edycja).
class TaskDraft extends Equatable {
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;

  const TaskDraft({
    required this.title,
    this.description,
    this.priority = TaskPriority.none,
    this.dueDate,
  });

  /// Wysyłamy wszystkie pola - `null` w `description` / `due_date` czyści wartość w API.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority.apiValue,
        'due_date': dueDate == null ? null : formatApiDate(dueDate!),
      };

  @override
  List<Object?> get props => [title, description, priority, dueDate];
}

/// `YYYY-MM-DD` - format daty (bez czasu) oczekiwany przez API.
String formatApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}
