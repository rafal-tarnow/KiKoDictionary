import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_routes.dart';
import 'presentation/sentences_provider.dart';
import 'presentation/widgets/sentence_form_dialog.dart';
import 'presentation/widgets/sentence_tile.dart';

class SentencesPage extends ConsumerWidget {
  const SentencesPage({super.key});

  // Uniwersalna metoda pokazująca elegancki, wyśrodkowany Dialog dla niezalogowanych
  void _showLoginPrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            // Ograniczamy szerokość, by wyglądał dobrze na tabletach/desktopie
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Okienko zajmuje tylko tyle miejsca ile treść
                children: [
                  const Icon(
                    Icons.bookmark_add_outlined,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Create your own notebook!",
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Log in or create a free account to save phrases, add your own translations, and sync your progress across devices.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Przycisk "CREATE ACCOUNT" (Zwracający największą uwagę)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Najpierw zamknij dialog
                        context.goNamed(AuthRoutes.register);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("CREATE ACCOUNT"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Przycisk "LOG IN" (Dyskretniejszy, dla powracających)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Najpierw zamknij dialog
                        context.goNamed(AuthRoutes.login);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.deepPurple.shade200),
                        foregroundColor: Colors.deepPurple.shade700,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("LOG IN"),
                    ),
                  ),

                  // Opcjonalny, subtelny przycisk zamknięcia
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade500,
                    ),
                    child: const Text("Maybe later"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentencesState = ref.watch(sentencesProvider);
    final notifier = ref.read(sentencesProvider.notifier);

    // Pobieramy stan logowania z AuthController
    final authState = ref.watch(authControllerProvider);
    final isLoggedIn = authState.isAuthenticated;

    // Własny ScaffoldMessenger: komunikaty z tej strony (np. "Moved to the end") pokazują się
    // w JEJ Scaffoldzie - nad paskiem stron, zamiast go zasłaniać - i nie przechodzą na inne strony.
    return ScaffoldMessenger(
      child: AppScaffold(
      title: "Sentences",
      actions: [
        if (isLoggedIn)
          IconButton(
            tooltip: "Refresh",
            onPressed: sentencesState.isLoading ? null : notifier.refreshCurrentPage,
            icon: sentencesState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                  )
                : const Icon(Icons.refresh),
          ),
      ],

      // FAB: Zawsze widoczny. Akcja zależy od tego, czy user jest zalogowany.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isLoggedIn) {
            // Pokaż normalny formularz dodawania
            showDialog(
              context: context,
              builder: (context) => const SentenceFormDialog(),
            );
          } else {
            // Zachęta do logowania w formie okna (Dialog)
            _showLoginPrompt(context, ref);
          }
        },
        //backgroundColor: Colors.deepPurple, // DODAJ TO
        //foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

      // Pasek Paginacji: Widoczny tylko dla zalogowanych, jeśli jest więcej niż 1 strona.
      bottomNavigationBar: isLoggedIn && sentencesState.totalPages > 1
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          sentencesState.currentPage > 1 &&
                              !sentencesState.isLoading
                          ? () => notifier.previousPage()
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Previous"),
                    ),
                    // Expanded: na wąskim ekranie napis się skraca zamiast wypychać przyciski poza ekran
                    Expanded(
                      child: Text(
                        "Page ${sentencesState.currentPage} / ${sentencesState.totalPages}",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          !sentencesState.isLastPage &&
                              !sentencesState.isLoading
                          ? () => notifier.nextPage()
                          : null,
                      label: const Text("Next"),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            )
          : null,

      body: Column(
        children: [
          // Pasek Błędu (Tylko dla zalogowanych)
          if (isLoggedIn && sentencesState.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Error: ${sentencesState.errorMessage}',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      notifier.refreshCurrentPage();
                    },
                    icon: Icon(Icons.refresh, color: Colors.red.shade900),
                    label: Text(
                      "Retry",
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: (!isLoggedIn)
                // 1. WIDOK DLA NIEZALOGOWANEGO: "Teaser" (zajawka) bez logowania
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 72,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Your notebook is empty",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Click the + button below to add your first sentence, or save one from the Community tab.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                // 2. WIDOK DLA ZALOGOWANEGO (Ładowanie, Pusta lista lub Pełna lista)
                : sentencesState.isLoading && sentencesState.sentences.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sentencesState.sentences.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add,
                            size: 72,
                            color: Colors.deepPurple.shade100,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "You don't have any sentences yet.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add your own phrases using the + button, or look for inspiration in the Community tab.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Przeciąganie jak w Daily Tasks / Projects: uchwyt po lewej
                      // + długie przytrzymanie kafelka na ekranach dotykowych.
                      // Między stronami przenosi się z menu kafelka ("Move to top" / "Move to end").
                      ReorderableListView.builder(
                        itemCount: sentencesState.sentences.length,
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: 80,
                        ), // Odstęp na FAB
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) => Material(
                          elevation: 6,
                          color: Colors.transparent,
                          child: child,
                        ),
                        onReorderItem: (oldIndex, newIndex) async {
                          final success = await notifier.reorder(oldIndex, newIndex);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to move the sentence."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        itemBuilder: (context, index) {
                          final item = sentencesState.sentences[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(item.id),
                            index: index,
                            child: SentenceTile(
                              sentence: item,
                              index: index,
                              isFirstOverall: sentencesState.isFirstOverall(index),
                              isLastOverall: sentencesState.isLastOverall(index),
                            ),
                          );
                        },
                      ),
                      if (sentencesState.isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 4),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      ),
    );
  }
}
