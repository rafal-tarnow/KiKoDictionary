import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sentences_repository.dart';
import 'sentences_provider.dart';
import '../../../core/network/api_error_handler.dart';

// Używamy prostego Providera, a nie StateNotifier, bo ten kontroler
// nie przechowuje stanu (stateless logic), tylko wykonuje akcję.
final deleteSentenceControllerProvider = Provider((ref) {
  return DeleteSentenceController(ref);
});

class DeleteSentenceController {
  final Ref _ref;

  DeleteSentenceController(this._ref);

  Future<void> deleteSentence({
    required BuildContext context,
    required int sentenceId,
  }) async {
    // 1. "Fire and forget" logic from UI perspective (dialog już zamknięty)

    final repo = _ref.read(sentencesRepositoryProvider);
    final notifier = _ref.read(sentencesProvider.notifier);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Wywołanie API (asynchronicznie)
      await repo.deleteSentence(sentenceId);

      // Zabezpieczenie przed wyciekiem
      if (!context.mounted) return;
      // Jeśli API zwróci 200 OK, usuwamy element z listy w UI
      notifier.removeSentenceLocally(sentenceId);

      // Feedback dla użytkownika (Snackbar)
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Usunięto zdanie.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Obsługa błędu

      if(!context.mounted) return;

      final friendlyMessage = ApiErrorHandler.getErrorMessage(e);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
