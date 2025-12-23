import 'package:equatable/equatable.dart';

// Equatable pozwala porównywać obiekty po wartościach pól, a nie referencji w pamięci.
// To jak przeładowanie operatora == w C++.
class Sentence extends Equatable {
  final int id;
  final String sentence;
  final String language;
  final String translation;
  // created_at przychodzi jako string, w prawdziwym projekcie parsujemy to na DateTime
  final String createdAt; 

  const Sentence({
    required this.id,
    required this.sentence,
    required this.language,
    required this.translation,
    required this.createdAt,
  });

  // Factory constructor - w C++ to byłaby statyczna metoda "createFromJson"
  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] as int,
      sentence: json['sentence'] as String,
      language: json['language'] as String,
      translation: json['translation'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  @override
  List<Object?> get props => [id, sentence, language, translation, createdAt];
}