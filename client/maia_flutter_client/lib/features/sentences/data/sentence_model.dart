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
  // Ręczna kolejność na liście "My Sentences" (mniejsza = wyżej)
  final double position;

  const Sentence({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
    this.position = 0,
  });

  /// Tryb nauki ukrywa tekst po angielsku. Zwykle jest to tłumaczenie (język docelowy 'en');
  /// tylko gdy angielski jest językiem źródłowym, ukrywamy oryginał.
  bool get hidesOriginalText => sourceLanguage == 'en' && targetLanguage != 'en';

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
      // JSON może przysłać int (1000) albo double (1500.5); starsze odpowiedzi nie mają pola
      position: (json['position'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, originalText, translatedText, sourceLanguage, targetLanguage, createdAt, position];
}