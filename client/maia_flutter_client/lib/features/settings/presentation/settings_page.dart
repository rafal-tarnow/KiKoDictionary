import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/navigation_provider.dart';
import 'controllers/settings_controller.dart';
import 'widgets/language_selector.dart';
import 'widgets/username_editor.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {

// Metoda wywołująca dialog z potwierdzeniem
  Future<void> _confirmAccountDeletion(BuildContext context) async {
    // ================= ZMIANA =================
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Wymusza podjęcie decyzji przyciskami (nie można kliknąć w tło, żeby zamknąć)
      builder: (BuildContext dialogContext) {
        return const _DeleteAccountDialog(); // Odwołanie do naszej nowej klasy z polem tekstowym
      },
    );
    // ==========================================

    // Jeśli użytkownik przepisał tekst i potwierdził w dialogu
    if (confirmed == true && mounted) {
      _executeDeletion();
    }
  }

  Future<void> _executeDeletion() async {
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .deleteAccount();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Twoje konto zostało usunięte. Przykro nam, że odchodzisz!',
          ),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Przekierowanie na stronę główną (Index 0) po wylogowaniu
      ref.read(navigationIndexProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Lekko szersze na ustawienia
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Nagłówek ---
              const Row(
                children: [
                  Icon(Icons.settings, size: 32, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Text(
                    "Ustawienia konta",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const UsernameEditor(),

              const SizedBox(height: 16),

              const LanguageSelector(),

              // const SizedBox(height: 48),

              // Tutaj w przyszłości pojawią się inne karty (np. Powiadomienia, Język)
              // Card(
              //   elevation: 1,
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text(
              //           "Preferencje",
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //         const SizedBox(height: 8),
              //         Text(
              //           "Wkrótce pojawią się tutaj opcje konfiguracyjne aplikacji...",
              //           style: TextStyle(color: Colors.grey.shade600),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 48),

              // ================= DANGER ZONE =================
              const Text(
                "Strefa niebezpieczna",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Usunięcie konta",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Usunięcie konta spowoduje bezpowrotną utratę wszystkich danych związanych z Twoim profilem. "
                      "Tej operacji nie można cofnąć.",
                      style: TextStyle(color: Colors.red.shade900, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Box z błędem wewnątrz Danger Zone (jeśli API wyrzuci błąd przy usuwaniu)
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Przycisk akcji
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => _confirmAccountDeletion(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: state.isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.delete_forever),
                        label: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("TRWALE USUŃ KONTO"),
                      ),
                    ),
                  ],
                ),
              ),
              // ================= END DANGER ZONE =================
            ],
          ),
        ),
      ),
    );
  }
}


// ================= ZMIANA: NOWY WIDGET DO POTWIERDZANIA =================
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _textController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    // ZMIANA: Zmieniono wymaganą frazę na "usuń konto"
    final isValid = value.trim().toLowerCase() == 'usuń konto';
    
    if (isValid != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                  SizedBox(width: 12),
                  Text(
                    "Trwałe usunięcie konta",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Ta operacja jest nieodwracalna. Stracisz dostęp do wszystkich swoich zwrotów, słówek i statystyk nauki.",
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              
              // Instrukcja dla użytkownika
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  children: const [
                    TextSpan(text: "Aby potwierdzić, przepisz poniżej słowa: "),
                    TextSpan(
                      text: "USUŃ KONTO",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Pole tekstowe do wpisywania
              TextField(
                controller: _textController,
                onChanged: _onTextChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Wpisz 'USUŃ KONTO'",
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Przyciski akcji
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("ANULUJ"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isButtonEnabled
                        ? () => Navigator.of(context).pop(true)
                        : null, // Jeśli tekst się nie zgadza, przycisk jest nieaktywny
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600, // Ciemniejszy, "krwisty" czerwony
                      foregroundColor: Colors.white, // Biały tekst dla aktywnego
                      disabledBackgroundColor: Colors.red.shade300, // Lekko wyblakły czerwony dla nieaktywnego
                      disabledForegroundColor: Colors.white, // Wymuszenie białego tekstu dla nieaktywnego!
                    ),
                    child: const Text("TAK, USUŃ KONTO"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ================= KONIEC ZMIANY =================