import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../user/presentation/controllers/user_controller.dart';
import '../controllers/settings_controller.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nasłuchujemy stanu użytkownika (żeby znać obecny język)
    final userState = ref.watch(userControllerProvider);
    // Nasłuchujemy stanu ustawień (czy właśnie trwa zapisywanie)
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
                Icon(Icons.language, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "Twój język (Native Language)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Wybierz język, z którego będziesz uczył się angielskiego. W tym języku będą wyświetlane tłumaczenia.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Obsługa różnych stanów (loading/error/data)
            userState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(
                'Błąd pobierania profilu: $err',
                style: const TextStyle(color: Colors.red),
              ),
              data: (user) {
                if (user == null || user.profile == null) {
                  return const Text("Brak danych profilu.");
                }

                final currentLang = user.profile!.nativeLanguage;

                return DropdownButtonFormField<String>(
                  initialValue: currentLang,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  // Blokujemy dropdown, jeśli w tle trwa zapisywanie
                  items: AppLanguages.supported.keys.map((String langCode) {
                    final flag = AppLanguages.getFlag(langCode);
                    final name = AppLanguages.getName(langCode);

                    return DropdownMenuItem(
                      value: langCode,
                      child: Text(
                        '$flag   $name', // Spacja dla czytelności
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: settingsState.isLoading
                      ? null
                      : (String? newValue) async {
                          if (newValue != null && newValue != currentLang) {
                            // Wywołujemy zapis w kontrolerze
                            final success = await ref
                                .read(settingsControllerProvider.notifier)
                                .updateLanguage(newValue);

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Język został zaktualizowany!"),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                );
              },
            ),

            // Komunikat błędu z zapisu (jeśli backend rzuci np. 422)
            if (settingsState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                settingsState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
