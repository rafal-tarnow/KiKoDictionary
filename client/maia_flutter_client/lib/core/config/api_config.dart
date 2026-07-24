class ApiConfig {
  ApiConfig._();

  static const String authBaseUrl = 'https://dev-auth.rafal-kruszyna.org';
  static const String sentencesBaseUrl = 'https://dev-sentences.rafal-kruszyna.org';
  static const String captchaBaseUrl = 'https://dev-captcha.rafal-kruszyna.org';
  
  // ================= DODAJ TO =================
  static const String todosBaseUrl = 'http://127.0.0.1:8004'; // Zmień na swój prod URL potem
  // ============================================

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}