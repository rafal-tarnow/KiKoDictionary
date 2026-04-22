class AppLanguages {
  AppLanguages._();

  static const Map<String, String> supported = {
    'en': 'English (Angielski)',
    'pl': 'Polski',
    'es': 'Español (Hiszpański)',
    'de': 'Deutsch (Niemiecki)',
    'fr': 'Français (Francuski)',
    'uk': 'Українська (Ukraiński)',
  };

  static String getName(String code) {
    return supported[code] ?? 'Nieznany ($code)';
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