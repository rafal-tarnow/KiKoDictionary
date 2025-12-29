import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sentence_model.dart';
import '../delete_sentence_controller.dart';
import '../edit_sentence_dialog.dart';

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
              // 1. Najpierw zamykamy dialog
              Navigator.of(ctx).pop();

              // 2. Delegujemy operację do kontrolera
              ref
                  .read(deleteSentenceControllerProvider)
                  .deleteSentence(context: context, sentenceId: sentence.id);
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                Icon(Icons.language, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  sentence.language,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,

        // --- SEKCJA TRAILING (POPRAWIONA) ---
        // Używamy FittedBox, aby uniknąć błędu "Bottom overflowed"
        trailing: FittedBox(
          fit: BoxFit.scaleDown, // Skaluje w dół, jeśli brakuje miejsca
          alignment: Alignment.centerRight,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Zajmuje tylko tyle miejsca ile trzeba
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Ikona USUWANIA (Czerwona)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, ref),
                tooltip: 'Usuń zdanie',
                // Ustawienia kompaktowe:
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 32, // Lekko mniejsza ikona dla bezpieczeństwa
              ),
              
              const SizedBox(height: 8), // Mniejszy odstęp (było 12, teraz 8)

              // 2. Ikona EDYCJI (Niebieska)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                   // TODO: Tu logika edycji
                   print("Kliknięto edycję id: ${sentence.id}");
                   showDialog(
                     context: context,
                     builder: (context) => EditSentenceDialog(sentence: sentence),
                   );
                },
                tooltip: 'Edytuj zdanie',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}