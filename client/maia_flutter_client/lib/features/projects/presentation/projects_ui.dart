import 'package:flutter/material.dart';
import '../data/models/project.dart';
import '../data/models/task_priority.dart';
import '../domain/action_result.dart';

/// Wspólne elementy prezentacji modułu Projects (kolory, formatowanie, komunikaty).
abstract final class ProjectsUi {
  /// Paleta kolorów projektów (Material). Pierwszy = domyślny (deepPurple, jak w całej aplikacji).
  static const List<String> palette = [
    '#673AB7', // deepPurple
    '#3F51B5', // indigo
    '#2196F3', // blue
    '#009688', // teal
    '#4CAF50', // green
    '#FF9800', // orange
    '#F44336', // red
    '#E91E63', // pink
    '#795548', // brown
    '#607D8B', // blueGrey
  ];

  static String get defaultColor => palette.first;

  static Color parseHex(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value == null ? Colors.deepPurple : Color(0xFF000000 | value);
  }

  static Color priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => Colors.red.shade600,
      TaskPriority.medium => Colors.orange.shade700,
      TaskPriority.low => Colors.blue.shade600,
      TaskPriority.none => Colors.grey.shade500,
    };
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// "Today", "Tomorrow", "Yesterday", "Dec 24" lub "Dec 24, 2027" (inny rok).
  static String formatDueDate(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final difference = DateTime(date.year, date.month, date.day).difference(today).inDays;

    switch (difference) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      case -1:
        return 'Yesterday';
    }
    final label = '${_months[date.month - 1]} ${date.day}';
    return date.year == current.year ? label : '$label, ${date.year}';
  }

  /// Pokazuje komunikat tylko przy błędzie (sukces jest widoczny od razu na liście).
  static void showFailure(BuildContext context, ActionResult result) {
    if (result case ActionFailure(:final message)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

extension ProjectColorX on Project {
  Color get displayColor => ProjectsUi.parseHex(color);
}
