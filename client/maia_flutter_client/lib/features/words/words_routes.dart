import 'package:go_router/go_router.dart';
import 'words_page.dart';

/// Trasy modułu Words.
abstract final class WordsRoutes {
  static const words = 'words';
  static const wordsPath = '/words';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: wordsPath, name: words, builder: (context, state) => const WordsPage())],
      );
}
