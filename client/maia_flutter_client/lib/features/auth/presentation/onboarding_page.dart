// ================= NOWY PLIK =================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_languages.dart';
import '../../../core/navigation_provider.dart';
import '../../settings/presentation/controllers/settings_controller.dart';
import '../../user/presentation/controllers/user_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  // Domyślnie proponujemy angielski, ale użytkownik musi to świadomie kliknąć
  String _selectedLangCode = 'en';

  Future<void> _submitOnboarding() async {
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    final success = await settingsNotifier.completeOnboarding(_selectedLangCode);

    // Zabezpieczamy zmianę flagi w backendzie. (Jeśli API FastAPI pozwala na wysłanie 
    // is_onboarding_completed: true w PATCH /me/profile, należy to dopisać w UserRepository).
    // Dla uproszczenia (jeśli nie ruszałeś API), traktujemy udane zapisanie profilu jako ukończenie.

    if (success && mounted) {
      // Ponownie pobieramy usera z bazy, aby mieć zaktualizowaną flagę (jeśli baza ją zmienia)
      await ref.read(userControllerProvider.notifier).fetchUser();
      
      // Przekierowujemy na stronę główną
      ref.read(navigationIndexProvider.notifier).state = 0; // HomePage
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gotowe! Możesz zacząć naukę."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nasłuchujemy błędów i ładowania
    final settingsState = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Ikona Powitalna ---
                    const Icon(
                      Icons.waving_hand_rounded,
                      size: 64,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 24),
                    
                    // --- Teksty ---
                    const Text(
                      "Witaj w aplikacji!",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Twoje konto zostało pomyślnie utworzone.\nZanim zaczniesz, wybierz swój język ojczysty, z którego będziesz się uczyć angielskiego.",
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // --- Wybór języka (Dokładnie jak w ustawieniach) ---
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLangCode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Mój język (Native Language)",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: AppLanguages.supported.keys.map((String langCode) {
                        final flag = AppLanguages.getFlag(langCode);
                        final name = AppLanguages.getName(langCode);
                        return DropdownMenuItem(
                          value: langCode,
                          child: Text('$flag   $name'),
                        );
                      }).toList(),
                      onChanged: settingsState.isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedLangCode = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 24),

                    // --- Ewentualny błąd z sieci ---
                    if (settingsState.error != null) ...[
                      Text(
                        settingsState.error!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Przycisk Start ---
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: settingsState.isLoading ? null : _submitOnboarding,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: settingsState.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("ZACZYNAMY!"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}