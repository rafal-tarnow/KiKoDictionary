// ================= ZAKTUALIZOWANY PLIK =================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation_provider.dart';
import 'presentation/community_sentences_provider.dart';
import 'presentation/widgets/community_sentence_tile.dart';
import '../../core/constants/app_languages.dart';
import '../../core/routing/app_page.dart';

class CommunitySentencesPage extends ConsumerWidget {
  const CommunitySentencesPage({super.key});

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
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.group_add_outlined,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Join the community!",
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Log in to save sentences from other users to your personal notebook.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(navigationProvider.notifier).state =
                            AppPage.register; // Rejestracja
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("SIGN UP"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(navigationProvider.notifier).state =
                            AppPage.login; // Logowanie
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("LOG IN"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      "Maybe later",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= [ZMIANA 1]: Nowoczesny Bottom Sheet filtru =================
  void _showFilterModal(
    BuildContext context,
    WidgetRef ref,
    String? currentSourceLang,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pozwala na lepsze dopasowanie wysokości
      showDragHandle:
          true, // Automatyczny, natywny uchwyt "pigułka" u góry panelu (Material 3)
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Zajmuje tylko tyle miejsca ile potrzebuje
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list),
                      SizedBox(width: 12),
                      Text(
                        "Filter by source language",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Flexible pozwala liście scrollować się, jeśli ekran jest za mały
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true, // Dopasowuje wysokość do ilości elementów
                    itemCount: AppLanguages.supported.length,
                    itemBuilder: (context, index) {
                      final langCode = AppLanguages.supported.keys.elementAt(
                        index,
                      );
                      final langName = AppLanguages.supported.values.elementAt(
                        index,
                      );
                      final flag = AppLanguages.getFlag(langCode);

                      final isSelected = langCode == currentSourceLang;

                      return ListTile(
                        leading: Text(
                          flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          langName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        // Pokazujemy ładnego checkmarka jeśli wybrano dany język
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        tileColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.3)
                            : null,
                        onTap: () {
                          ref
                              .read(communitySentencesProvider.notifier)
                              .setSourceLanguage(langCode);
                          Navigator.of(ctx).pop(); // Zamykamy panel
                        },
                      );
                    },
                  ),
                ),

                const Divider(),
                // Przycisk usunięcia filtrów
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(communitySentencesProvider.notifier)
                        .clearFilters();
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.public),
                  label: const Text("Show all languages"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ==============================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitySentencesProvider);
    final notifier = ref.read(communitySentencesProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      // ================= [ZMIANA 2]: Floating Action Button =================
      // Korzystamy z FAB.extended bez twardo wpisanego koloru.
      // Odziedziczy on ten sam kolor motywu, co zwykły okrągły FAB w sekcji prywatnej.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFilterModal(context, ref, state.sourceLang),
        icon: const Icon(Icons.filter_list),
        //backgroundColor: Colors.deepPurple, // DODAJ TO
        //foregroundColor: Colors.white, 
        label: Text(
          state.sourceLang != null
              ? 'Filter: ${AppLanguages.getFlag(state.sourceLang!)} ${state.sourceLang!.toUpperCase()}'
              : 'Filter',
        ),
      ),
      // ======================================================================

      // --- PASEK PAGINACJI ---
      bottomNavigationBar: state.totalPages > 1
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
                      onPressed: state.currentPage > 1 && !state.isLoading
                          ? () => notifier.previousPage()
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Previous"),
                    ),
                    Text(
                      "Page ${state.currentPage} of ${state.totalPages}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: !state.isLastPage && !state.isLoading
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
          // ================= [ZMIANA 3]: Usunięto górny pasek z filtrem =================
          // Dzięki temu cała strona to czysta lista i nie ma duplikacji akcji.

          // Pasek Błędu
          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Error: ${state.errorMessage}',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => notifier.refreshCurrentPage(),
                    icon: Icon(Icons.refresh, color: Colors.red.shade900),
                    label: Text(
                      "Retry",
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // --- LISTA ---
          Expanded(
            child: state.isLoading && state.sentences.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.sentences.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 72,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No sentences in this language",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Change your filters or check back later.",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView.separated(
                        itemCount: state.sentences.length,
                        // ================= [ZMIANA 4]: Poprawiony padding =================
                        // bottom: 80 zapewnia, że ostatni wpis na liście da się przescrollować
                        // powyżej przycisku Floating Action Button i nie jest on zasłonięty.
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: 80,
                        ),
                        separatorBuilder: (context, index) => Divider(
                          height: 16,
                          thickness: 0.5,
                          color: Colors.grey.shade300,
                          indent: 8,
                          endIndent: 8,
                        ),
                        itemBuilder: (context, index) {
                          return CommunitySentenceTile(
                            sentence: state.sentences[index],
                            onLoginPrompt: () => _showLoginPrompt(context, ref),
                          );
                        },
                      ),
                      if (state.isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
