import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../user/presentation/controllers/user_controller.dart';
import '../controllers/settings_controller.dart';

class UsernameEditor extends ConsumerStatefulWidget {
  const UsernameEditor({super.key});

  @override
  ConsumerState<UsernameEditor> createState() => _UsernameEditorState();
}

class _UsernameEditorState extends ConsumerState<UsernameEditor> {
  final _usernameCtrl = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // UX: Czyścimy błędy z API (np. "Nazwa zajęta"), gdy użytkownik zaczyna wpisywać nową nazwę
    _usernameCtrl.addListener(() {
      ref.read(settingsControllerProvider.notifier).clearUsernameError();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newName = _usernameCtrl.text.trim();
    if (newName.isEmpty || newName.length < 3) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateUsername(newName);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nazwa użytkownika została zmieniona!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge_outlined, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "Nazwa Użytkownika",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Ta nazwa widnieje w przestrzeni publicznej. Możesz w każdej chwili zmienić losowo wygenerowany identyfikator na swój własny.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),

            userState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text(
                "Nie udało się załadować profilu.",
                style: TextStyle(color: Colors.red),
              ),
              data: (user) {
                if (user == null) return const SizedBox.shrink();

                // Bezpieczne inicjowanie danych raz (Floating Label działa idealnie)
                if (!_isInitialized && _usernameCtrl.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _usernameCtrl.text = user.username;
                        _isInitialized = true;
                      });
                    }
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= [ZMIANA]: Precyzyjny Reaktywny Formularz =================
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _usernameCtrl,
                      builder: (context, value, child) {
                        
                        final currentInput = value.text.trim();
                        // ================= ZMIANA: Usunięto toLowerCase()! =================
                        // Teraz jeśli user w bazie ma "Ania", a w polu wpisze "ania",
                        // 'isSameAsCurrent' będzie miało wartość FALSE. Przycisk się odblokuje!
                        final isSameAsCurrent = currentInput == user.username;
                        // ===================================================================

                        // Dwustopniowa logika błędów UX:
                        final isEmpty = currentInput.isEmpty;
                        final isTooShort = !isEmpty && currentInput.length < 3;

                        String? validationError;
                        if (isEmpty) {
                          validationError =
                              "Nazwa użytkownika nie może być pusta";
                        } else if (isTooShort) {
                          validationError =
                              "Nazwa musi mieć co najmniej 3 znaki";
                        }

                        // Zablokuj przycisk, jeśli ładuje, tekst się nie zmienił LUB jest błąd walidacji
                        final isDisabled =
                            settingsState.isLoading ||
                            isSameAsCurrent ||
                            validationError != null;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usernameCtrl,
                                enabled: !settingsState.isLoading,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  labelText: "Twoja nazwa",
                                  // Wyświetlamy precyzyjny błąd
                                  errorText: validationError,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: isDisabled ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                              child: settingsState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("ZAPISZ"),
                            ),
                          ],
                        );
                      },
                    ),
                    // =========================================================================

                    // --- BŁĘDY Z SERWERA (Zajęty login + Podpowiedzi z bazy) ---
                    if (settingsState.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settingsState.error!,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  // ====== MAGIA UX: WYŚWIETLANIE SUGESTII (PIGUŁKI) ======
                                  if (settingsState.usernameSuggestions !=
                                          null &&
                                      settingsState
                                          .usernameSuggestions!
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      "Dostępne alternatywy:",
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: settingsState
                                          .usernameSuggestions!
                                          .map((suggestion) {
                                            return ActionChip(
                                              label: Text(suggestion),
                                              backgroundColor: Colors.white,
                                              side: BorderSide(
                                                color: Colors.red.shade200,
                                              ),
                                              labelStyle: TextStyle(
                                                color: Colors.red.shade900,
                                                fontSize: 13,
                                              ),
                                              onPressed: () {
                                                // Gdy user kliknie sugestię, wpisujemy ją w pole!
                                                _usernameCtrl.text = suggestion;
                                                ref
                                                    .read(
                                                      settingsControllerProvider
                                                          .notifier,
                                                    )
                                                    .clearUsernameError();
                                              },
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ],
                                  // =======================================================
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
