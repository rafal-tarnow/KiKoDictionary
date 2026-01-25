import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation_provider.dart';
import '../auth_controller.dart';

class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({super.key});

  static const int _loginPageIndex = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final bool isLoggedIn = authState.isAuthenticated;

    // --- STAN: ZALOGOWANY (Menu Popup) ---
    if (isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: PopupMenuButton<String>(
          offset: const Offset(0, 50),
          tooltip: 'Menu użytkownika',
          // Zaokrąglenie samego okienka menu
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          
          // KLUCZOWA ZMIANA:
          // Używamy parametru 'icon' zamiast 'child'.
          // Dzięki temu Flutter traktuje to jako standardową ikonę na pasku
          // i automatycznie dodaje okrągły efekt "ink splash" przy kliknięciu/najechaniu.
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.person, color: Colors.deepPurple, size: 20),
          ),
          
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout(context, ref);
            }
          },
          
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                "Moje Konto", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Wyloguj się', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // --- STAN: NIEZALOGOWANY (Przycisk Logowania) ---
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        tooltip: "Zaloguj się",
        // Tutaj też używamy standardowego IconButton, który ma okrągły splash
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.login, color: Colors.grey.shade700, size: 20),
        ),
        onPressed: () {
          ref.read(navigationIndexProvider.notifier).state = _loginPageIndex;
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wylogowano pomyślnie"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    ref.read(navigationIndexProvider.notifier).state = 0;
  }
}