class SentenceUpdate {
  // ================= [ZMIANA]: Zmiana pól w DTO =================
  final String? originalText;
  final String? translatedText;
  final String? sourceLanguage;
  final String? targetLanguage;

  const SentenceUpdate({
    this.originalText,
    this.translatedText,
    this.sourceLanguage,
    this.targetLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      if (originalText != null) 'original_text': originalText,
      if (translatedText != null) 'translated_text': translatedText,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
    };
  }
  // ==============================================================
}