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
    if (!_formKey.currentState!.validate()) return;

    // 1. Pobieramy ID captchy z Twojego istniejącego kontrolera captchy
    final captchaState = ref.read(captchaControllerProvider);
    if (captchaState.captcha == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Błąd Captchy')));
      return;
    }

    // 2. Wywołujemy rejestrację
    final success = await ref.read(authControllerProvider.notifier).register(
      email: _emailCtrl.text,
      username: _userCtrl.text,
      password: _passCtrl.text,
      captchaId: captchaState.captcha!.id, // UUID z serwera
      captchaAnswer: _captchaInputCtrl.text, // Tekst wpisany przez usera
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konto założone! Zaloguj się.')));
      Navigator.pop(context); // Wróć do logowania
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (v) => v!.length < 3 ? 'Za krótkie' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: "Hasło"),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Za krótkie hasło' : null,
              ),
              const SizedBox(height: 24),
              
              // --- TWOJA CAPTCHA ---
              // Reużywamy Twój widget! To jest siła modułowości.
              CaptchaBox(
                answerController: _captchaInputCtrl,
              ),
              // ---------------------

              const SizedBox(height: 24),
              if (authState.error != null)
                 Text(authState.error!, style: const TextStyle(color: Colors.red)),

              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading ? const CircularProgressIndicator() : const Text("ZAREJESTRUJ SIĘ"),
              )),
            ],
          ),
        ),
      ),
    );
  }
}