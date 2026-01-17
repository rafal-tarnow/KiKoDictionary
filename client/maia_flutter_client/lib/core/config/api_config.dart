class ApiConfig {
  // Unikamy instancjonowania tej klasy
  ApiConfig._();

  // Adresy bazowe dla środowiska DEV
  // W przyszłości można tu dodać logikę do przełączania na PROD
  static const String authBaseUrl = 'https://dev-auth.rafal-kruszyna.org';
  static const String sentencesBaseUrl = 'https://dev-sentences.rafal-kruszyna.org';
  static const String captchaBaseUrl = 'https://dev-captcha.rafal-kruszyna.org';
  
  // Timeouty
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}