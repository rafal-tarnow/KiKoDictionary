// ================= NOWY PLIK =================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../user/presentation/controllers/user_controller.dart';

class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userControllerProvider);

    return Card(
      elevation: 1,
      // Delikatnie złote tło dla konta PRO
      color: userState.valueOrNull?.isPro == true 
          ? Colors.amber.shade50 
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Złota ramka dla PRO
        side: userState.valueOrNull?.isPro == true 
            ? BorderSide(color: Colors.amber.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: userState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => const Text("Failed to load subscription data."),
          data: (user) {
            if (user == null) return const SizedBox.shrink();

            final isPro = user.isPro;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPro ? Icons.workspace_premium : Icons.stars_outlined,
                      color: isPro ? Colors.amber.shade700 : Colors.deepPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Account Plan",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    // Elegancki "Chip" ze statusem
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPro ? Colors.amber.shade600 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPro ? "PRO" : "FREE",
                        style: TextStyle(
                          color: isPro ? Colors.white : Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Opis zależny od planu (Tłumaczy DLACZEGO warto mieć PRO)
                Text(
                  isPro 
                    ? "You are currently enjoying the Premium plan! Your sentence character limit is maximized to 569 characters."
                    : "You are on the Free plan. Your sentences are limited to 150 characters. Upgrade to PRO to unlock longer texts!",
                  style: TextStyle(
                    color: isPro ? Colors.amber.shade900 : Colors.grey.shade600, 
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Przycisk akcji (Upgrade / Manage)
                SizedBox(
                  width: double.infinity,
                  child: isPro 
                    // Przycisk dla PRO (np. do anulowania lub faktur)
                    ? OutlinedButton(
                        onPressed: () {
                          // TODO: Integracja z płatnościami (Stripe/RevenueCat)
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade800,
                          side: BorderSide(color: Colors.amber.shade700),
                        ),
                        child: const Text("MANAGE SUBSCRIPTION"),
                      )
                    // Przycisk dla FREE (zachęcający)
                    : FilledButton.icon(
                        onPressed: () {
                          // TODO: Nawigacja do ekranu cennika/zakupu
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text("UPGRADE TO PRO"),
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}