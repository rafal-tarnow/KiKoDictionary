class TodoItem {
  final int id;
  final String content;
  final bool isCompleted;
  final double position;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.content,
    required this.isCompleted,
    required this.position,
    required this.createdAt,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      content: json['content'],
      isCompleted: json['is_completed'],
      // Rzutowanie na double, bo JSON może przysłać int (np. 1000) lub float (1000.5)
      position: (json['position'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Ułatwia lokalne aktualizacje (np. zaznaczenie checkboxa bez czekania na serwer)
  TodoItem copyWith({
    int? id,
    String? content,
    bool? isCompleted,
    double? position,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}