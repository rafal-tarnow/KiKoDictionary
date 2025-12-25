import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sentence_model.dart';
import '../delete_sentence_controller.dart';

class SentenceTile extends ConsumerWidget {
  final Sentence sentence;

  const SentenceTile({super.key, required this.sentence});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Potwierdzenie"),
        content: const Text("Usunąć to zdanie?"),
        actions: [
          // Przycisk "Nie"
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Zamknij dialog
            },
            child: const Text("Nie"),
          ),
          // Przycisk "Tak" - Czerwony
          TextButton(
            onPressed: () {
              // 1. Najpierw zamykamy dialog (non-blocking feel)
              Navigator.of(ctx).pop();
              
              // 2. Delegujemy operację do kontrolera
              ref.read(deleteSentenceControllerProvider).deleteSentence(
                    context: context,
                    sentenceId: sentence.id,
                  );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // Czerwony tekst
            ),
            child: const Text("Tak"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          child: Text(sentence.id.toString()),
        ),
        title: Text(
          sentence.sentence,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              sentence.translation,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.language,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  sentence.language,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        // --- IKONA KOSZA PO PRAWEJ ---
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context, ref),
          tooltip: 'Usuń zdanie',
        ),
      ),
    );
  }
}