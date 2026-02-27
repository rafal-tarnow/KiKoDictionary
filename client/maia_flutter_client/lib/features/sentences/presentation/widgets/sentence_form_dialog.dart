// ==========================================
// NOWY PLIK: sentence_form_dialog.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_sizes.dart';
import '../../data/sentence_model.dart';
import '../add_sentence_controller.dart';
import '../edit_sentence_controller.dart';

class SentenceFormDialog extends ConsumerStatefulWidget {
  // Jeśli sentence jest null -> jesteśmy w trybie DODAWANIA
  // Jeśli sentence nie jest null -> jesteśmy w trybie EDYCJI
  final Sentence? sentence;

  const SentenceFormDialog({super.key, this.sentence});

  @override
  ConsumerState<SentenceFormDialog> createState() => _SentenceFormDialogState();
}

class _SentenceFormDialogState extends ConsumerState<SentenceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _sentenceController;
  late TextEditingController _translationController;

  // Właściwość pomocnicza określająca w jakim trybie jesteśmy
  bool get _isEditMode => widget.sentence != null;

  @override
  void initState() {
    super.initState();
    // Inicjalizujemy kontrolery. Jeśli to edycja - wpisujemy stare dane.
    _sentenceController = TextEditingController(text: _isEditMode ? widget.sentence!.sentence : '');
    _translationController = TextEditingController(text: _isEditMode ? widget.sentence!.translation : '');
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    bool success = false;

    if (_isEditMode) {
      // LOGIKA EDYCJI
      final controller = ref.read(editSentenceControllerProvider.notifier);
      success = await controller.editSentence(
        id: widget.sentence!.id,
        sentence: _sentenceController.text,
        translation: _translationController.text,
        language: widget.sentence!.language, // Zachowujemy obecny język
      );
    } else {
      // LOGIKA DODAWANIA
      final controller = ref.read(addSentenceControllerProvider.notifier);
      success = await controller.addSentence(
        sentence: _sentenceController.text,
        translation: _translationController.text,
        language: 'en', // Domyślnie angielski przy dodawaniu
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(); // Zamykamy dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Zaktualizowano zdanie' : 'Dodano nowe zdanie!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obserwujemy stan odpowiedniego kontrolera w zależności od trybu
    final isLoading = _isEditMode 
        ? ref.watch(editSentenceControllerProvider).isLoading 
        : ref.watch(addSentenceControllerProvider).isLoading;
        
    final hasError = _isEditMode 
        ? ref.watch(editSentenceControllerProvider).hasError 
        : ref.watch(addSentenceControllerProvider).hasError;
        
    final errorText = _isEditMode 
        ? ref.watch(editSentenceControllerProvider).error?.toString() 
        : ref.watch(addSentenceControllerProvider).error?.toString();

    // Tytuł zależy od trybu
    final titleText = _isEditMode ? "Edytuj zdanie #${widget.sentence!.id}" : "Dodaj nowe zdanie";

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxMobileWidth * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titleText,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                
                if (hasError)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Błąd: $errorText',
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _sentenceController,
                          decoration: const InputDecoration(
                            labelText: '🌍 Native Language',
                            hintText: 'e.g. Meaning in your language',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          enabled: !isLoading,
                          minLines: 3,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          validator: (value) {
                            if ((value == null || value.isEmpty) && _translationController.text.isEmpty) {
                              return 'Wypełnij zdanie LUB tłumaczenie';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _translationController,
                          decoration: const InputDecoration(
                            labelText: '🇬🇧 English',
                            hintText: 'e.g. The weather is beautiful today.',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          enabled: !isLoading,
                          minLines: 2,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          validator: (value) {
                            if ((value == null || value.isEmpty) && _sentenceController.text.isEmpty) {
                              return 'Wypełnij zdanie LUB tłumaczenie';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
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
                                child: Text(
                                  _isEditMode ? widget.sentence!.language.toUpperCase() : 'EN',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
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
                          : Text(_isEditMode ? 'Zapisz zmiany' : 'Dodaj zdanie'),
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