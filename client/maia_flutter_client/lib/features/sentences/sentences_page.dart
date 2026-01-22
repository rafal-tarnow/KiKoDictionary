import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/sentences_provider.dart';
import 'presentation/add_sentence_dialog.dart';
import 'presentation/widgets/sentence_tile.dart';

class SentencesPage extends ConsumerWidget {
  const SentencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentencesState = ref.watch(sentencesProvider);
    final notifier = ref.read(sentencesProvider.notifier);

    return Scaffold(
      //backgroundColor: Colors.transparent,
      //backgroundColor: Colors.red,
      backgroundColor: const Color(0xFFFFFFFF),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddSentenceDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: SafeArea(
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
                    sentencesState.currentPage > 1 && !sentencesState.isLoading
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
                    !sentencesState.isLastPage && !sentencesState.isLoading
                    ? () => notifier.nextPage()
                    : null,
                label: const Text("Następna"),
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          if (sentencesState.errorMessage != null)
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
                  // Przycisk "Ponów" bezpośrednio przy błędzie
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

          // Container(
          //   padding: const EdgeInsets.all(8),
          //   color: Colors.red.shade100,
          //   width: double.infinity,
          //   child: Text(
          //     'Błąd: ${sentencesState.errorMessage}',
          //     style: const TextStyle(color: Colors.red),
          //   ),
          // ),
          Expanded(
            child: sentencesState.isLoading && sentencesState.sentences.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sentencesState.sentences.isEmpty
                ? const Center(child: Text("Brak zdań do wyświetlenia."))
                : Stack(
                    children: [
                      ListView.separated(
                        itemCount: sentencesState.sentences.length,
                        padding: const EdgeInsets.all(8),
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
                          // --- UŻYCIE NOWEGO WIDGETU ---
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
