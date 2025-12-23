import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/sentences_provider.dart';

class SentencesPage extends ConsumerWidget {
  const SentencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obserwujemy stan naszego providera
    // To jak bindowanie property w QML: text: model.someText
    final state = ref.watch(sentencesProvider);
    // Dostep do metod (kontrolera) bez obserwowania zmian
    final notifier = ref.read(sentencesProvider.notifier);

    return Column(
      children: [
        // 1. Obsługa błędów
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

        // 2. Lista danych lub Loader
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.sentences.isEmpty
                  ? const Center(child: Text("Brak zdań do wyświetlenia."))
                  : ListView.builder(
                      itemCount: state.sentences.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final item = state.sentences[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Text(item.id.toString()),
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
        ),

        // 3. Paginacja (Dolny pasek)
        Container(
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
                    : null, // null wyłącza przycisk (enabled: false)
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
                // Trick w Flutterze: zmiana kolejności dzieci w Row
                // Directionality.rtl zmieniłoby układ ikony, ale tutaj ręcznie układamy:
                label: const Text("Następna"),
                icon: const Icon(Icons.arrow_forward), 
              ),
            ],
          ),
        ),
      ],
    );
  }
}