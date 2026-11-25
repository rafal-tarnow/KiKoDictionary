import 'package:go_router/go_router.dart';
import 'community_sentences_page.dart';
import 'sentences_page.dart';

/// Trasy modułu Sentences. Dwie osobne sekcje Drawera = dwie gałęzie,
/// więc każda pamięta swój stan (stronę listy, przewinięcie) przy przełączaniu.
abstract final class SentencesRoutes {
  static const mySentences = 'my-sentences';
  static const mySentencesPath = '/sentences';
  static const community = 'community';
  static const communityPath = '/community';

  static List<StatefulShellBranch> branches() => [
        StatefulShellBranch(
          routes: [GoRoute(path: mySentencesPath, name: mySentences, builder: (context, state) => const SentencesPage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: communityPath, name: community, builder: (context, state) => const CommunitySentencesPage()),
          ],
        ),
      ];
}
