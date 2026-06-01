// ================= NOWY PLIK =================
// Profesjonalne podejście: Enum zamiast twardych liczb (magic numbers).
// Kolejność tutaj definiuje indeks w IndexedStack.
enum AppPage {
  home,               // dawniej 0
  dictionary,         // dawniej 1
  words,              // dawniej 2
  sentences,          // dawniej 3
  register,           // dawniej 4
  login,              // dawniej 5
  test,               // dawniej 6
  //health,             // dawniej 7
  captcha,            // dawniej 8
  forgotPassword,     // dawniej 9
  settings,           // dawniej 10
  onboarding,         // dawniej 11
  communitySentences, // dawniej 12
}

// Opcjonalne rozszerzenie (Extension), jeśli potrzebujesz dodatkowych właściwości dla danej strony
extension AppPageExtension on AppPage {
  // Przykładowo, możemy tu zdefiniować, czy strona wymaga ukrycia menu bocznego (drawer)
  bool get isFullScreen {
    return this == AppPage.onboarding;
  }
}