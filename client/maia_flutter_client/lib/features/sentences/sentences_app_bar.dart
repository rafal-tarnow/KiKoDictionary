import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './presentation/sentences_provider.dart';

class SentencesAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SentencesAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obserwujemy stan, aby np. pokazać inny spinner na przycisku odświeżania,
    // jeśli trwa ładowanie (opcjonalny bajer, tutaj prosta wersja).
    final state = ref.watch(sentencesProvider);
    final sentencesNotifier = ref.read(sentencesProvider.notifier);

    return AppBar(
      title: const Text("Sentences"),
      elevation: 2,
      actions: [
        // Przycisk Odśwież
        IconButton(
          icon: state.isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54,)
                )
              : const Icon(Icons.refresh),
          tooltip: "Odśwież listę",
          onPressed: state.isLoading 
              ? null // Zablokuj, jeśli już ładuje
              : () {
                  // Tu wywołujemy logikę "Backendu"
                  sentencesNotifier.refreshCurrentPage();
                },
        ),
        // Opcjonalnie inne przyciski, np. sortowanie
        // IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}