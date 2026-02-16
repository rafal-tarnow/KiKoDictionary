import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/core/navigation_provider.dart';
import 'controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  // Indeks strony logowania w MainShell (według app.dart jest to 5)
  static const int _loginPageIndex = 5;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Ukrywamy klawiaturę
    FocusScope.of(context).unfocus();

    // Wywołujemy logikę z kontrolera
    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetLink(_emailCtrl.text.trim());

    if (success && mounted) {
      // Opcjonalnie: czyścimy pole po sukcesie
      _emailCtrl.clear();
      
      // SnackBar jako dodatkowe potwierdzenie
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link został wysłany! Sprawdź skrzynkę e-mail.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Opcjonalnie: Powrót do logowania po sukcesie
      // ref.read(navigationIndexProvider.notifier).state = _loginPageIndex;
    }
  }

  void _navigateToLogin() {
    ref.read(navigationIndexProvider.notifier).state = _loginPageIndex;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return Scaffold(
      // AppBar jest opcjonalny, jeśli strona jest w MainShell, 
      // ale dla ForgotPassword często chcemy "czysty" ekran bez menu.
      // Tutaj zostawiam body, bo MainShell dostarcza AppBar.
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
                  // --- 1. Linia powrotu ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: state.isLoading ? null : _navigateToLogin,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text("Powrót do logowania"),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Zmniejsza padding, by wyrównać do lewej
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // --- 2. Ikona (Email) ---
                  Icon(
                    state.isSuccess ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                    size: 80,
                    color: state.isSuccess ? Colors.green : Colors.deepPurple,
                  ),
                  
                  const SizedBox(height: 24),

                  // --- 3. Nagłówek ---
                  Text(
                    state.isSuccess ? "Sprawdź skrzynkę" : "Przypomnij hasło",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),

                  // --- 4. Podtytuł (Instrukcja) ---
                  Text(
                    state.isSuccess 
                      ? "Jeśli podany adres email istnieje w naszej bazie, wysłaliśmy na niego link do resetowania hasła."
                      : "Podaj adres email, na który wyślemy link do\nresetowania hasła.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // --- 5. Pole Email ---
                  // Ukrywamy pole lub blokujemy po sukcesie, żeby użytkownik skupił się na komunikacie
                  if (!state.isSuccess)
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      enabled: !state.isLoading,
                      decoration: const InputDecoration(
                        labelText: "Adres email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        hintText: "np. tom@example.com",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wpisz adres email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Niepoprawny format email';
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 24),

                  // --- Wyświetlanie błędu ---
                  if (state.error != null)
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
                                state.error!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --- 6. Przycisk Akcji ---
                  if (!state.isSuccess)
                    FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("WYŚLIJ LINK RESETUJĄCY"),
                    )
                  else
                    // Przycisk powrotu do logowania po sukcesie
                    FilledButton.icon(
                      onPressed: _navigateToLogin,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text("WRÓĆ DO LOGOWANIA"),
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