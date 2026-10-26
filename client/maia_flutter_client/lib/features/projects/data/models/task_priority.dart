/// Priorytet zadania - wartości zgodne z API (`none | low | medium | high`).
enum TaskPriority {
  none('none', 'No priority'),
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const TaskPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TaskPriority fromApi(String? value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.apiValue == value,
      orElse: () => TaskPriority.none,
    );
  }
}
