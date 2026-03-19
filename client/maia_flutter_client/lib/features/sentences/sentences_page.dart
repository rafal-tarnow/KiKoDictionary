import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../../core/navigation_provider.dart';
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
                    "Stwórz własny notatnik!",
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Zaloguj się lub załóż darmowe konto, aby móc zapisywać zwroty, dodawać własne tłumaczenia i synchronizować postępy między urządzeniami.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Przycisk "ZAŁÓŻ KONTO" (Zwracający największą uwagę)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Najpierw zamknij dialog
                        ref.read(navigationIndexProvider.notifier).state =
                            4; // Index Rejestracji
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("ZAŁÓŻ KONTO"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Przycisk "ZALOGUJ SIĘ" (Dyskretniejszy, dla powracających)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Najpierw zamknij dialog
                        ref.read(navigationIndexProvider.notifier).state =
                            5; // Index Logowania
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
                      child: const Text("ZALOGUJ SIĘ"),
                    ),
                  ),

                  // Opcjonalny, subtelny przycisk zamknięcia
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade500,
                    ),
                    child: const Text("Może później"),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

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
                      label: const Text("Poprzednia"),
                    ),
                    Text(
                      "Strona ${sentencesState.currentPage}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          !sentencesState.isLastPage &&
                              !sentencesState.isLoading
                          ? () => notifier.nextPage()
                          : null,
                      label: const Text("Następna"),
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
                      'Błąd: ${sentencesState.errorMessage}',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      notifier.refreshCurrentPage();
                    },
                    icon: Icon(Icons.refresh, color: Colors.red.shade900),
                    label: Text(
                      "Ponów",
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
                            "Twój notatnik jest pusty",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Kliknij przycisk + poniżej, aby dodać swoje pierwsze zdanie lub skopiuj je ze Społeczności.",
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
                            "Nie masz jeszcze żadnych zdań.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Dodaj własne zwroty przyciskiem + lub poszukaj inspiracji w zakładce Społeczność.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView.separated(
                        itemCount: sentencesState.sentences.length,
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: 80,
                        ), // Odstęp na FAB
                        separatorBuilder: (context, index) {
                          return Divider(
                            height: 16,
                            thickness: 0.5,
                            color: Colors.grey.shade400,
                            indent: 8,
                            endIndent: 8,
                          );
                        },
                        itemBuilder: (context, index) {
                          final item = sentencesState.sentences[index];
                          return SentenceTile(sentence: item);
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
    );
  }
}
