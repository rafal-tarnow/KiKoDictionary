import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/main_drawer.dart';
import 'presentation/captcha_controller.dart';
import 'presentation/widgets/captcha_box.dart';

class CaptchaPage extends ConsumerStatefulWidget {
  const CaptchaPage({super.key});

  @override
  ConsumerState<CaptchaPage> createState() => _CaptchaPageState();
}

class _CaptchaPageState extends ConsumerState<CaptchaPage> {
  final _captchaInputController = TextEditingController();

  @override
  void dispose() {
    _captchaInputController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    // Ukrywamy klawiaturę
    FocusScope.of(context).unfocus();
    
    final answer = _captchaInputController.text;
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wpisz kod!")),
      );
      return;
    }

    final success = await ref
        .read(captchaControllerProvider.notifier)
        .verifyCaptcha(answer);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Captcha zweryfikowana pomyślnie!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obserwujemy stan, aby wiedzieć np. czy trwa ładowanie
    final captchaState = ref.watch(captchaControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Captcha Test"),
        elevation: 2,
      ),
      drawer: const MainDrawer(), // Dodajemy boczny pasek
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Demonstracja modułu Captcha",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Poniższy komponent jest niezależny i gotowy do użycia na ekranach logowania/rejestracji.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // --- REUŻYWALNY WIDGET CAPTCHA ---
            CaptchaBox(
              answerController: _captchaInputController,
              onRefresh: () {
                // Opcjonalny callback, np. logowanie zdarzenia
                debugPrint("Użytkownik odświeżył captchę");
              },
            ),
            // ---------------------------------

            const SizedBox(height: 24),

            // Przycisk "Verify" - specyficzny dla tej strony testowej
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: captchaState.isLoading ? null : _verify,
                icon: const Icon(Icons.check_circle_outline),
                label: captchaState.isLoading
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text("ZWERYFIKUJ CAPTCHĘ"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}