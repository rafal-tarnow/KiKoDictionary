class ApiConfig {
  ApiConfig._();

  static const String authBaseUrl = 'https://dev-auth.rafal-kruszyna.org';
  static const String sentencesBaseUrl = 'https://dev-sentences.rafal-kruszyna.org';
  static const String captchaBaseUrl = 'https://dev-captcha.rafal-kruszyna.org';
  static const String todosBaseUrl = 'https://dev-todo.rafal-kruszyna.org';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}