class UsernameTakenException implements Exception {
  final String message;
  final String suggestion;

  UsernameTakenException({
    required this.message, 
    required this.suggestion
  });

  @override
  String toString() => message;
}