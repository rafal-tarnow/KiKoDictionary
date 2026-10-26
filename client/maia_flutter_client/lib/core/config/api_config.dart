class ApiConfig {
  ApiConfig._();

  // --- BACKEND PRZEZ INTERNET (Cloudflare Tunnel) ---
  static const String authBaseUrl = 'https://dev-auth.rafal-kruszyna.org';
  static const String sentencesBaseUrl = 'https://dev-sentences.rafal-kruszyna.org';
  static const String captchaBaseUrl = 'https://dev-captcha.rafal-kruszyna.org';
  static const String todosBaseUrl = 'https://dev-todo.rafal-kruszyna.org';
  static const String projectsBaseUrl = 'https://dev-projects.rafal-kruszyna.org';

  // --- BACKEND LOKALNIE (Docker na tym komputerze) ---
  // Zakomentuj blok wyżej i odkomentuj ten.
  // Windows desktop / web: 127.0.0.1, emulator Androida: 10.0.2.2,
  // fizyczny telefon: IP tego komputera w LAN.
  // static const String authBaseUrl = 'http://127.0.0.1:8002';
  // static const String sentencesBaseUrl = 'http://127.0.0.1:8003';
  // static const String captchaBaseUrl = 'http://127.0.0.1:8001';
  // static const String todosBaseUrl = 'http://127.0.0.1:8004';
  // static const String projectsBaseUrl = 'http://127.0.0.1:8005';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
