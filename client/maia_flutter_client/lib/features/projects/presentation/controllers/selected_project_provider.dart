import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'projects_session_provider.dart';

/// ID otwartego projektu (`null` = widok listy projektów).
///
/// Nawigacja lista -> szczegóły odbywa się wewnątrz strony (jak reszta aplikacji
/// opartej o `IndexedStack`), dzięki czemu widok zostaje w "słupku" aplikacji
/// i zachowuje wspólny AppBar oraz Drawer. Reset po zmianie sesji (logout/login).
final selectedProjectIdProvider = StateProvider<int?>((ref) {
  ref.watch(projectsSessionProvider);
  return null;
});
