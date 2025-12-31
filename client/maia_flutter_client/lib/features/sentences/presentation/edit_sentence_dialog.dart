import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentence_model.dart';
import 'edit_sentence_controller.dart';
import '../../../core/app_sizes.dart';

class EditSentenceDialog extends ConsumerStatefulWidget {
  final Sentence sentence; // Przyjmujemy obiekt do edycji

  const EditSentenceDialog({super.key, required this.sentence});

  @override
  ConsumerState<EditSentenceDialog> createState() => _EditSentenceDialogState();
}

class _EditSentenceDialogState extends ConsumerState<EditSentenceDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Kontrolery
  late TextEditingController _sentenceController;
  late TextEditingController _translationController;
  late TextEditingController _languageController;

  @override
  void initState() {
    super.initState();
    // Inicjalizujemy kontrolery wartościami z obiektu przekazanego w konstruktorze
    _sentenceController = TextEditingController(text: widget.sentence.sentence);
    _translationController = TextEditingController(text: widget.sentence.translation);
    _languageController = TextEditingController(text: widget.sentence.language);
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _translationController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Pobieramy notifiera kontrolera
    final controller = ref.read(editSentenceControllerProvider.notifier);

    final success = await controller.editSentence(
      id: widget.sentence.id,
      sentence: _sentenceController.text,
      translation: _translationController.text,
      language: _languageController.text,
    );

    // Sprawdzamy mounted zanim użyjemy contextu po await (C++ safety rule!)
    if (success && mounted) {
      Navigator.of(context).pop(); // Zamykamy dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zaktualizowano zdanie'),
          behavior: SnackBarBehavior.floating, // Wygląda lepiej
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(editSentenceControllerProvider);
    final isLoading = asyncState.isLoading;

    return Dialog(
      // Dialog zamiast AlertDialog, żeby mieć większą kontrolę nad layoutem
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxMobileWidth*0.9), // Max szerokość na tabletach
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Dialog zajmie tyle ile trzeba
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Edytuj zdanie #${widget.sentence.id}",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                
                // Obsługa błędu
                if (asyncState.hasError)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Błąd: ${asyncState.error}',
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                // Lista pól w Flexible/ScrollView na wypadek małego ekranu/klawiatury
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _sentenceController,
                          decoration: const InputDecoration(
                            labelText: 'Oryginał',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true, // Ważne przy multiline
                          ),
                          enabled: !isLoading,
                          minLines: 3, // Domyślnie wysokie na 3 linie
                          maxLines: null, // Rozszerza się w nieskończoność
                          keyboardType: TextInputType.multiline,
                          //validator: (v) => v!.isEmpty ? 'Pole wymagane' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _translationController,
                          decoration: const InputDecoration(
                            labelText: 'Tłumaczenie',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          enabled: !isLoading,
                          minLines: 2,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          //validator: (v) => v!.isEmpty ? 'Pole wymagane' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // --- ZMIANA: Zwykły Label informacyjny ---
                        // Zamiast pola tekstowego pokazujemy po prostu informację
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0), // Lekkie wcięcie, żeby zrównać z labelami inputów
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
                                child: Text(
                                  widget.sentence.language.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* 
                        // --- Oryginalna wersja edycyjna (zakomentowana) ---
                        TextFormField(
                          controller: _languageController,
                          decoration: const InputDecoration(
                            labelText: 'Język',
                            border: OutlineInputBorder(),
                            helperText: 'Kod języka, np. en, de, es', //ISO 639-1 
                          ),
                          enabled: !isLoading,
                          //validator: (v) => v!.isEmpty ? 'Pole wymagane' : null,
                        ),
                        */
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Przyciski akcji
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton( // FilledButton to nowy standard Material 3 (zamiast ElevatedButton)
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Zapisz zmiany'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}