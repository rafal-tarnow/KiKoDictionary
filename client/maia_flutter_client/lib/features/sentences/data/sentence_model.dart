import 'package:equatable/equatable.dart';

// Equatable pozwala porównywać obiekty po wartościach pól, a nie referencji w pamięci.
// To jak przeładowanie operatora == w C++.
class Sentence extends Equatable {
  final int id;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  // created_at przychodzi jako string, w prawdziwym projekcie parsujemy to na DateTime
  final String createdAt; 

  const Sentence({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] as int,
      // ================= [ZMIANA 2]: Mapowanie nowych kluczy z JSON =================
      originalText: json['original_text'] as String,
      translatedText: json['translated_text'] as String,
      sourceLanguage: json['source_language'] as String,
      targetLanguage: json['target_language'] as String,
      // ==============================================================================
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, originalText, translatedText, sourceLanguage, targetLanguage, createdAt];
}