import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation_provider.dart';
import '../auth_controller.dart';

class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({super.key});

  // Stała definiująca index strony logowania w MainShell
  // W przyszłości warto to przenieść do konfigu routingu (np. GoRouter), 
  // ale przy obecnej architekturze IndexedStack trzymamy to tutaj.
  static const int _loginPageIndex = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final bool isLoggedIn = authState.isAuthenticated;

    // --- STAN: ZALOGOWANY (Menu Popup) ---
    if (isLoggedIn) {
      return PopupMenuButton<String>(
        offset: const Offset(0, 50), // Przesunięcie menu w dół
        tooltip: 'Menu użytkownika',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        
        // Wygląd przycisku na AppBarze
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.person, color: Colors.deepPurple),
            // Tutaj w przyszłości możesz dać: 
            // backgroundImage: NetworkImage(user.avatarUrl),
          ),
        ),
        
        // Akcja po wybraniu elementu z menu
        onSelected: (value) {
          if (value == 'logout') {
            _handleLogout(context, ref);
          }
          // Tu dodasz kolejne case'y np. 'profile', 'settings'
        },
        
        // Lista opcji w menu
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          // Opcjonalnie: Nagłówek menu z emailem usera
          const PopupMenuItem<String>(
            enabled: false, // Nieklikalny nagłówek
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
      );
    }

    // --- STAN: NIEZALOGOWANY (Przycisk Logowania) ---
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        tooltip: "Zaloguj się",
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.login, color: Colors.grey.shade700, size: 20),
        ),
        onPressed: () {
          // Przekierowanie do strony logowania
          ref.read(navigationIndexProvider.notifier).state = _loginPageIndex;
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Wywołanie logiki wylogowania
    await ref.read(authControllerProvider.notifier).logout();
    
    // Opcjonalnie: Feedback dla użytkownika
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wylogowano pomyślnie"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    // Opcjonalnie: Przekierowanie na stronę główną po wylogowaniu
    ref.read(navigationIndexProvider.notifier).state = 0;
  }
}