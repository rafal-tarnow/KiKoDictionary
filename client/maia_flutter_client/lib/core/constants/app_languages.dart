class AppLanguages {
  AppLanguages._();

  static const Map<String, String> supported = {
    'en': 'English',
    'pl': 'Polski (Polish)',
    'es': 'Español (Spanish)',
    'de': 'Deutsch (German)',
    'fr': 'Français (French)',
    'uk': 'Українська (Ukrainian)',
  };

  static String getName(String code) {
    return supported[code] ?? 'Unknown ($code)';
  }

  // ================= ZMIANA: NOWA FUNKCJA DO FLAG =================
  static String getFlag(String code) {
    switch (code) {
      case 'pl': return '🇵🇱';
      case 'en': return '🇬🇧'; // lub '🇺🇸' w zależności od preferencji
      case 'es': return '🇪🇸';
      case 'de': return '🇩🇪';
      case 'fr': return '🇫🇷';
      case 'uk': return '🇺🇦';
      case '--': return ' ';
      default: return '🌍'; // Fallback
    }
  }
}