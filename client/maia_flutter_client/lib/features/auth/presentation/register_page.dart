import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/navigation_provider.dart';
import '../../captcha/presentation/widgets/captcha_box.dart';
import '../../captcha/presentation/captcha_controller.dart';
import 'controllers/register_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolery
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _captchaInputCtrl = TextEditingController();

  // Lokalny stan widoku
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Dodajemy listener, który wyczyści sugestię/błąd jak user zacznie pisać w username
    _userCtrl.addListener(() {
      final regState = ref.read(registerControllerProvider);
      // Sprawdzamy stan rejestracji
      if (regState.usernameSuggestion != null || regState.error != null) {
        // Wywołujemy metodę czyszczącą tylko jeśli faktycznie jest co czyścić
        // (żeby nie odświeżać UI przy każdym znaku bez potrzeby)
        ref.read(registerControllerProvider.notifier).clearSuggestion();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _captchaInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 1. Walidacja lokalna formularza
    if (!_formKey.currentState!.validate()) return;

    // 2. Walidacja czy captcha w ogóle załadowana
    final captchaState = ref.read(captchaControllerProvider);
    if (captchaState.captcha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd Captchy. Odśwież obrazek.')),
      );
      return;
    }

    // UX: Ukryj klawiaturę
    FocusScope.of(context).unfocus();

    // 3. Strzał do API
    final success = await ref
        .read(registerControllerProvider.notifier)
        .register(
          email: _emailCtrl.text,
          username: _userCtrl.text,
          password: _passCtrl.text,
          captchaId: captchaState.captcha!.id,
          captchaAnswer: _captchaInputCtrl.text,
        );

    // 4. Obsługa wyniku
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konto założone! Możesz się zalogować.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Czyścimy formularz
      _emailCtrl.clear();
      _userCtrl.clear();
      _passCtrl.clear();
      _captchaInputCtrl.clear();

      // Przekierowanie do logowania (Index 5 w MainShell)
      ref.read(navigationIndexProvider.notifier).state = 5;

      // Pobranie nowej captchy "na zaś"
      ref.read(captchaControllerProvider.notifier).fetchCaptcha();
    } else {
      // W przypadku błędu (np. zły kod captcha), musimy pobrać nowy obrazek,
      // bo stary token na serwerze został "spalony" przy próbie weryfikacji.
      if (mounted) {
        _captchaInputCtrl.clear();
        ref.read(captchaControllerProvider.notifier).fetchCaptcha();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ZMIANA: Watchujemy stan rejestracji
    final regState = ref.watch(registerControllerProvider);

    return Scaffold(
      // Body jest centrowane i scrollowalne - identycznie jak w LoginPage
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- NAGŁÓWEK ---
                  const Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Utwórz konto",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Dołącz do nas i zacznij naukę.",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- EMAIL ---
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Adres email",
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !regState.isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wpisz email';
                      if (!v.contains('@')) return 'Niepoprawny format email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- USERNAME ---
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nazwa użytkownika",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !regState.isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty){
                        return 'Wpisz nazwę użytkownika';
                      }
                      if (v.length < 3){
                        return 'Minimum 3 znaki';
                      }
                      return null;
                    },
                  ),
                  //------------------ USERNAME SUGGESTION ---------
                  if (regState.usernameSuggestion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () {
                          // Wpisujemy sugestię do pola
                          _userCtrl.text = regState.usernameSuggestion!;
                          // Czyścimy błąd w kontrolerze
                          ref
                              .read(registerControllerProvider.notifier)
                              .clearSuggestion();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Login zajęty. Kliknij, aby użyć: ${regState.usernameSuggestion}",
                                  style: TextStyle(color: Colors.blue.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  //------------------------------------------------
                  const SizedBox(height: 16),

                  // --- HASŁO (z okiem) ---
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_isPasswordVisible, // Logika ukrywania
                    decoration: InputDecoration(
                      labelText: "Hasło",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      // Ikona oka
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !regState.isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wpisz hasło';

                      // Sprawdzamy wszystkie warunki naraz
                      bool hasMinLength = v.length >= 6;
                      bool hasDigit = RegExp(r'\d').hasMatch(v);
                      bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(v);

                      // Jeśli którykolwiek warunek nie jest spełniony, zwracamy pełną instrukcję
                      // Zwracamy odrazu bład na wszystkie warunki, żeby użytkownik miał
                      // lepsze UI/UX experience, i zeby odrazu znał wszystkie warunki prawidlowego hasla - nie usuwac tego komentarza
                      if (!hasMinLength || !hasDigit || !hasLetter) {
                        return 'Hasło musi mieć min. 6 znaków, literę i cyfrę';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- CAPTCHA ---
                  const Text(
                    "Weryfikacja bezpieczeństwa",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CaptchaBox(answerController: _captchaInputCtrl),

                  const SizedBox(height: 24),

                  // --- ERROR BOX (Wystylizowany jak w Login) ---
                  if (regState.error != null &&
                      regState.usernameSuggestion == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                regState.error!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --- PRZYCISK REJESTRACJI ---
                  FilledButton(
                    onPressed: regState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: regState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("UTWÓRZ KONTO"),
                  ),

                  const SizedBox(height: 16),

                  // --- LINK DO LOGOWANIA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Masz już konto?"),
                      TextButton(
                        onPressed: regState.isLoading
                            ? null
                            : () {
                                // Nawigacja do logowania (Index 5 w AppShell)
                                ref
                                        .read(navigationIndexProvider.notifier)
                                        .state =
                                    5;
                              },
                        child: const Text("Zaloguj się"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
