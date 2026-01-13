import 'dart:convert'; // Do base64Decode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../captcha_controller.dart';

class CaptchaBox extends ConsumerStatefulWidget {
  final TextEditingController answerController;
  final VoidCallback? onRefresh;

  const CaptchaBox({
    super.key, 
    required this.answerController,
    this.onRefresh,
  });

  @override
  ConsumerState<CaptchaBox> createState() => _CaptchaBoxState();
}

class _CaptchaBoxState extends ConsumerState<CaptchaBox> {
  
  @override
  void initState() {
    super.initState();
    widget.answerController.addListener(() {
      ref.read(captchaControllerProvider.notifier).resetVerificationStatus();
    });
  }

  // --- NOWA METODA POMOCNICZA ---
  // Usuwa nagłówek "data:image/png;base64," jeśli istnieje
  String _cleanBase64(String base64String) {
    if (base64String.contains(',')) {
      return base64String.split(',').last;
    }
    return base64String;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captchaControllerProvider);
    final controller = ref.read(captchaControllerProvider.notifier);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Obrazek Captcha
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: state.isLoading && state.captcha == null
                  ? const Center(child: CircularProgressIndicator())
                  : state.captcha != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            // --- TUTAJ POPRAWKA ---
                            // Używamy metody pomocniczej _cleanBase64
                            base64Decode(_cleanBase64(state.captcha!.image)), 
                            fit: BoxFit.contain, // Zmienione na contain, żeby nie ucinało tekstu captchy
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Błąd wyświetlania obrazka: $error');
                              return const Center(child: Icon(Icons.broken_image));
                            },
                          ),
                        )
                      : const Center(child: Text("Brak Captchy")),
            ),

            const SizedBox(height: 12),

            // 2. Wiersz: Pole tekstowe + Przycisk odświeżania
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.answerController,
                    decoration: InputDecoration(
                      labelText: 'Wpisz kod z obrazka',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      enabledBorder: state.isVerified == false
                          ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red))
                          : null,
                      focusedBorder: state.isVerified == false
                          ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: state.isLoading 
                    ? null 
                    : () {
                        controller.fetchCaptcha();
                        widget.answerController.clear();
                        if(widget.onRefresh != null) widget.onRefresh!();
                      },
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : const Icon(Icons.refresh),
                  tooltip: "Nowy kod",
                ),
              ],
            ),
            
            // 3. Informacja o błędzie
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              
            if (state.isVerified == false)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Niepoprawny kod. Spróbuj ponownie.",
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              
             if (state.isVerified == true)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Kod poprawny!",
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}