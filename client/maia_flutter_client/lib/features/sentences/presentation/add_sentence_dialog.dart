import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_sentence_controller.dart';

class AddSentenceDialog extends ConsumerStatefulWidget {
  const AddSentenceDialog({super.key});

  @override
  ConsumerState<AddSentenceDialog> createState() => _AddSentenceDialogState();
}

class _AddSentenceDialogState extends ConsumerState<AddSentenceDialog> {
  // Klucz formularza pozwala na walidację
  final _formKey = GlobalKey<FormState>();
  
  // Kontrolery pól tekstowych
  final _sentenceController = TextEditingController();
  final _translationController = TextEditingController();
  final _languageController = TextEditingController(text: 'EN'); // Domyślna wartość

  @override
  void dispose() {
    // Sprzątanie zasobów (jak destruktor w C++)
    _sentenceController.dispose();
    _translationController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Wywołujemy metodę z kontrolera Riverpod
      final success = await ref.read(addSentenceControllerProvider.notifier).addSentence(
            sentence: _sentenceController.text,
            language: _languageController.text,
            translation: _translationController.text,
          );

      if (success && mounted) {
        Navigator.of(context).pop(); // Zamknij dialog po sukcesie
        
        // Pokaż powiadomienie (Snackbar)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano nowe zdanie!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obserwujemy stan asynchroniczny (loading/error)
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
              // Wyświetlanie błędu z API, jeśli wystąpił
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
                decoration: const InputDecoration(labelText: 'Zdanie (np. Hello World)'),
                enabled: !isLoading, // Blokuj inputy podczas wysyłania
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Pole wymagane';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _translationController,
                decoration: const InputDecoration(labelText: 'Tłumaczenie (np. Witaj Świecie)'),
                enabled: !isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Pole wymagane';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _languageController,
                decoration: const InputDecoration(labelText: 'Język (np. EN)'),
                enabled: !isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Pole wymagane';
                  return null;
                },
              ),
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