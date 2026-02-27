import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_sentence_controller.dart';

class AddSentenceDialog extends ConsumerStatefulWidget {
  const AddSentenceDialog({super.key});

  @override
  ConsumerState<AddSentenceDialog> createState() => _AddSentenceDialogState();
}

class _AddSentenceDialogState extends ConsumerState<AddSentenceDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _sentenceController = TextEditingController();
  final _translationController = TextEditingController();

  @override
  void dispose() {
    _sentenceController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Przed wysłaniem warto upewnić się, że formularz jest poprawny
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(addSentenceControllerProvider.notifier).addSentence(
            sentence: _sentenceController.text, // Może być pusty string
            language: 'en',
            translation: _translationController.text, // Może być pusty string
          );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano nowe zdanie!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(addSentenceControllerProvider);
    final isLoading = asyncState.isLoading;

    return AlertDialog(
      title: const Text('Dodaj nowe zdanie'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (asyncState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Błąd: ${asyncState.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                
              TextFormField(
                controller: _sentenceController,
                decoration: const InputDecoration(labelText: 'Zdanie (np. Witaj Świecie)'),
                enabled: !isLoading,
                // ZMIANA TUTAJ:
                validator: (value) {
                  // Sprawdzamy, czy aktualne pole jest puste ORAZ czy drugie pole jest puste
                  if ((value == null || value.isEmpty) && _translationController.text.isEmpty) {
                    return 'Wypełnij zdanie LUB tłumaczenie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _translationController,
                decoration: const InputDecoration(labelText: 'Tłumaczenie (np. Hello World)'),
                enabled: !isLoading,
                // ZMIANA TUTAJ:
                validator: (value) {
                  // To samo sprawdzenie w drugą stronę
                  if ((value == null || value.isEmpty) && _sentenceController.text.isEmpty) {
                    return 'Wypełnij zdanie LUB tłumaczenie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- ZMIANA: Skopiowany wygląd z EditSentenceDialog ---
              // Zastąpiono TextFormField statycznym, ładnym wskaźnikiem języka
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Język: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light 
                            ? Colors.grey.shade200 
                            : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EN', // ZMIANA: Ustawione na sztywno
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // --- KONIEC ZMIANY ---
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Text('Zapisz'),
        ),
      ],
    );
  }
}