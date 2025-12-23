class SentenceCreate {
  final String sentence;
  final String language;
  final String translation;

  const SentenceCreate({
    required this.sentence,
    required this.language,
    required this.translation,
  });

  // Metoda toJson konwertuje obiekt na Mapę, którą Dio zamieni na JSON.
  // W C++ to byłaby metoda serializująca do QJsonObject.
  Map<String, dynamic> toJson() {
    return {
      'sentence': sentence,
      'language': language,
      'translation': translation,
    };
  }
}