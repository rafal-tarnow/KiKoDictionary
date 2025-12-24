import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/sentences_provider.dart';
import 'presentation/add_sentence_dialog.dart';

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
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
            // ZMIANA LOGIKI WYŚWIETLANIA:
            
            // 1. Jeśli ładujemy i nie mamy żadnych danych -> Wielki Loader (Inicjalizacja)
            child: state.isLoading && state.sentences.isEmpty
                ? const Center(child: CircularProgressIndicator())
                
                // 2. Jeśli nie ładujemy i lista pusta -> Info o braku danych
                : state.sentences.isEmpty
                    ? const Center(child: Text("Brak zdań do wyświetlenia."))
                    
                    // 3. Mamy dane (nawet jeśli właśnie trwa odświeżanie) -> Pokaż listę
                    : Stack(
                        children: [
                          // Warstwa 1: Lista
                          ListView.builder(
                            itemCount: state.sentences.length,
                            padding: const EdgeInsets.only(
                                left: 8, top: 8, right: 8, bottom: 20),
                            itemBuilder: (context, index) {
                              final item = state.sentences[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    child: Text(
                                      item.id.toString()
                                      ),
                                  ),
                                  title: Text(
                                    item.sentence,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        item.translation,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.language, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.language,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),

                          // Warstwa 2: Dyskretny pasek ładowania na górze (tylko przy odświeżaniu)
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