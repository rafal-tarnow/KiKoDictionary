class SentenceUpdate {
  // W API te pola są 'anyOf string/null', więc tutaj String?
  final String? sentence;
  final String? language;
  final String? translation;

  const SentenceUpdate({
    this.sentence,
    this.language,
    this.translation,
  });

  Map<String, dynamic> toJson() {
    // Serializujemy tylko te pola, które nie są nullem (chociaż w edycji wyślemy wszystkie)
    return {
      if (sentence != null) 'sentence': sentence,
      if (language != null) 'language': language,
      if (translation != null) 'translation': translation,
    };
  }
}