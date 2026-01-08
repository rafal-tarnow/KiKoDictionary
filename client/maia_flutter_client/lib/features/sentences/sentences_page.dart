import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/sentences_provider.dart';
import 'presentation/add_sentence_dialog.dart';
import 'presentation/widgets/sentence_tile.dart';
import '../../core/widgets/main_drawer.dart';

class SentencesPage extends ConsumerWidget {
  const SentencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sentencesProvider);
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
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                label: const Text("Poprzednia"),
              ),

              Text(
                "Strona ${state.currentPage}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              ElevatedButton.icon(
                onPressed: !state.isLastPage && !state.isLoading
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
          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Text(
                'Błąd: ${state.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Expanded(
            child: state.isLoading && state.sentences.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.sentences.isEmpty
                    ? const Center(child: Text("Brak zdań do wyświetlenia."))
                    : Stack(
                        children: [
                          ListView.separated(
                            itemCount: state.sentences.length,
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
                              final item = state.sentences[index];
                              // --- UŻYCIE NOWEGO WIDGETU ---
                              return SentenceTile(sentence: item);
                            },
                          ),
                          if (state.isLoading)
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
