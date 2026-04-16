class SentenceCreate {
  // ================= [ZMIANA]: Zmiana pól w DTO =================
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;

  const SentenceCreate({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'original_text': originalText,
      'translated_text': translatedText,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
    };
  }
  // ==============================================================
}