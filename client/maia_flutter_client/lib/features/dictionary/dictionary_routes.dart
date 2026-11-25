import 'package:go_router/go_router.dart';
import 'dictionary_page.dart';

/// Trasy modułu Dictionary (strona w budowie, poza Drawerem).
abstract final class DictionaryRoutes {
  static const dictionary = 'dictionary';
  static const dictionaryPath = '/dictionary';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: dictionaryPath, name: dictionary, builder: (context, state) => const DictionaryPage())],
      );
}
