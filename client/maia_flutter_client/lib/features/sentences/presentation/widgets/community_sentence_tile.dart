// ================= NOWY PLIK =================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sentence_model.dart';
import '../clone_sentence_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class CommunitySentenceTile extends ConsumerStatefulWidget {
  final Sentence sentence;
  // Funkcja callback, żeby otworzyć dialog logowania przekazany ze strony głównej
  final VoidCallback onLoginPrompt; 

  const CommunitySentenceTile({
    super.key, 
    required this.sentence,
    required this.onLoginPrompt,
  });

  @override
  ConsumerState<CommunitySentenceTile> createState() => _CommunitySentenceTileState();
}

class _CommunitySentenceTileState extends ConsumerState<CommunitySentenceTile> {
  // Lokalny stan optymistyczny (zabezpiecza przed podwójnym kliknięciem i daje natychmiastowy feedback)
  bool _isSaved = false; 

  Future<void> _handleClone() async {
    final authState = ref.read(authControllerProvider);
    
    // 1. Jeśli nie zalogowany -> Pokaż zachętę do logowania
    if (!authState.isAuthenticated) {
      widget.onLoginPrompt();
      return;
    }

    // 2. Optymistyczny UI - od razu zaznaczamy jako zapisane (UI responsywność)
    setState(() => _isSaved = true);

    // 3. Wywołujemy API
    final success = await ref
        .read(cloneSentenceControllerProvider.notifier)
        .cloneSentence(widget.sentence.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zdanie skopiowane do Twojego notatnika!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!success && mounted) {
      // 4. Jeśli błąd (np. brak sieci, albo "Już masz to zdanie") - cofamy optymistyczne UI
      setState(() => _isSaved = false);
      
      final errorMsg = ref.read(cloneSentenceControllerProvider).error?.toString() ?? "Błąd klonowania";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jeśli controller ładuje to konkretne id, pokazujemy mały spinner (można uprościć)
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Subtelne obramowanie, żeby odróżnić od "Moich Zdań"
        side: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.1)), 
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
        title: Text(
          widget.sentence.originalText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              widget.sentence.translatedText,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.sentence.sourceLanguage.toUpperCase()} ➔ ${widget.sentence.targetLanguage.toUpperCase()}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: _isSaved ? null : _handleClone, // Wyłącz jeśli już zapisane
          tooltip: "Zapisz do moich",
          icon: Icon(
            _isSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
            color: _isSaved ? Colors.green : Colors.deepPurple,
            size: 28,
          ),
        ),
      ),
    );
  }
}