class UsernameConflictException implements Exception {
  final String message;
  final List<String> suggestions;

  UsernameConflictException({
    required this.message,
    required this.suggestions,
  });

  @override
  String toString() => message;
}