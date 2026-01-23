import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/navigation_provider.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Kontrolery tekstu (odpowiednik property string w QML)
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Lokalny stan widoku (dla ukrywania hasła)
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 1. Walidacja formularza
    if (!_formKey.currentState!.validate()) return;

    // Ukryj klawiaturę (UX)
    FocusScope.of(context).unfocus();

    // 2. Wywołanie logiki biznesowej
    // Używamy read, bo wykonujemy akcję jednorazową
    final success = await ref.read(authControllerProvider.notifier).login(
      _usernameCtrl.text,
      _passCtrl.text,
    );

    // 3. Obsługa wyniku (tylko nawigacja/sukces, błędy są w stanie authState)
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zalogowano pomyślnie!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Przekierowanie na stronę główną (Index 0)
      ref.read(navigationIndexProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obserwujemy stan autentykacji (np. czy trwa ładowanie, czy jest błąd)
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      // AppBar opcjonalny, zależy czy strona jest w Drawerze czy osobno
      // Tutaj zakładam, że będzie w MainShell, więc AppBar dostarczy shell.
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
                  // --- Nagłówek ---
                  const Icon(Icons.lock_person_outlined, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  Text(
                    "Witaj ponownie!",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Zaloguj się, aby kontynuować naukę.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- Username Field ---
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nazwa użytkownika",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next, // Przycisk "Dalej"
                    enabled: !authState.isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wpisz nazwę użytkownika';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Password Field ---
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Hasło",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.done, // Przycisk "Gotowe"
                    onFieldSubmitted: (_) => _submit(), // Enter zatwierdza
                    enabled: !authState.isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wpisz hasło';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- Error Message Display ---
                  // Wyświetlamy błąd globalny z Controllera (np. 401 Unauthorized)
                  if (authState.error != null)
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
                                authState.error!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --- Submit Button ---
                  FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("ZALOGUJ SIĘ"),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // --- Link do rejestracji ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Nie masz konta?"),
                      TextButton(
                        onPressed: authState.isLoading 
                            ? null 
                            : () {
                                // Nawigacja do rejestracji (Index 4 w AppShell)
                                ref.read(navigationIndexProvider.notifier).state = 4; 
                              },
                        child: const Text("Zarejestruj się"),
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