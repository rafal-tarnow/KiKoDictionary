import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../captcha/presentation/widgets/captcha_box.dart';
import '../../captcha/presentation/captcha_controller.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  // Kontroler do captchy przekazujemy do Twojego widgetu
  final _captchaInputCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _captchaInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 1. Walidacja lokalna (Flutter)
    // Jeśli formularz jest źle wypełniony (np. brak @ w emailu),
    // NIE wysyłamy żądania do serwera.
    // Dzięki temu NIE "palamy" captchy i nie musimy jej odświeżać. To jest dobre UX.
    if (!_formKey.currentState!.validate()) return;

    // Pobieramy ID captchy z Twojego istniejącego kontrolera captchy
    final captchaState = ref.read(captchaControllerProvider);
    if (captchaState.captcha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd Captchy. Odśwież obrazek.')),
      );
      return;
    }

    // Ukrywamy klawiaturę dla lepszego wrażenia
    FocusScope.of(context).unfocus();

    // 2. Wywołujemy rejestrację (Strzał do API)
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailCtrl.text,
          username: _userCtrl.text,
          password: _passCtrl.text,
          captchaId: captchaState.captcha!.id, // UUID z serwera
          captchaAnswer: _captchaInputCtrl.text, // Tekst wpisany przez usera
        );

    // 3. Obsługa wyniku
    if (success && mounted) {
      // SUKCES:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konto założone! Zaloguj się.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Wróć do logowania
    } else {
      // PORAŻKA (np. błąd 409 - zajęty email, błąd 422 - zła captcha):
      // W tym momencie serwer już przetworzył token captchy i oznaczył go jako zużyty (lub był błędny).
      // Musimy bezwzględnie pobrać nowy obrazek, inaczej kolejna próba (nawet z dobrym emailem)
      // zwróci błąd "Invalid Captcha / Captcha already used".

      if (mounted) {
        // Czyścimy pole wpisywania kodu, bo stary kod jest już nieważny
        _captchaInputCtrl.clear();

        // Wymuszamy pobranie nowej captchy
        ref.read(captchaControllerProvider.notifier).fetchCaptcha();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Rejestracja")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v!.contains('@') ? null : 'Błędny email',
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (v) => v!.length < 3 ? 'Za krótkie' : null,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: "Hasło"),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wpisz hasło';
                  
                  // Sprawdzamy wszystkie warunki naraz
                  bool hasMinLength = v.length >= 6;
                  bool hasDigit = RegExp(r'\d').hasMatch(v);
                  bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);
                  
                  // Jeśli którykolwiek warunek nie jest spełniony, zwracamy pełną instrukcję
                  if (!hasMinLength || !hasDigit || !hasLetter) {
                    return 'Hasło musi mieć min. 6 znaków, literę i cyfrę';
                  }
                  
                  return null;
                },
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 24),

              // --- TWOJA CAPTCHA ---
              // Reużywamy Twój widget! To jest siła modułowości.
              CaptchaBox(answerController: _captchaInputCtrl),

              // ---------------------
              const SizedBox(height: 24),

              // Wyświetlanie błędu z Controllera (który ma już ładny tekst z ApiErrorHandler)
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("ZAREJESTRUJ SIĘ"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
