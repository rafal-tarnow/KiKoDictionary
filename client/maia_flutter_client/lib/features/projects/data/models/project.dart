import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final int id;
  final String name;
  final String? description;

  /// Kolor w formacie `#RRGGBB` (tak jak w API).
  final String color;
  final double position;
  final int taskCount;
  final int completedTaskCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.position,
    required this.taskCount,
    required this.completedTaskCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Postęp 0.0 - 1.0 (pusty projekt = 0).
  double get progress => taskCount == 0 ? 0 : completedTaskCount / taskCount;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      // JSON może przysłać int (1000) albo double (1000.5)
      position: (json['position'] as num).toDouble(),
      taskCount: json['task_count'] as int? ?? 0,
      completedTaskCount: json['completed_task_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Project copyWith({
    String? name,
    String? description,
    String? color,
    double? position,
    int? taskCount,
    int? completedTaskCount,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      position: position ?? this.position,
      taskCount: taskCount ?? this.taskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        position,
        taskCount,
        completedTaskCount,
        createdAt,
        updatedAt,
      ];
}

/// Dane z formularza projektu (tworzenie i edycja).
class ProjectDraft extends Equatable {
  final String name;
  final String? description;
  final String color;

  const ProjectDraft({required this.name, this.description, required this.color});

  /// Wysyłamy wszystkie pola - `description: null` czyści opis po stronie API.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'color': color,
      };

  @override
  List<Object?> get props => [name, description, color];
}
