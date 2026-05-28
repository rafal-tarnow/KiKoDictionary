import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation_provider.dart';
import '../../../../core/constants/app_languages.dart'; // NOWY IMPORT
import '../../../user/presentation/controllers/user_controller.dart'; // NOWY IMPORT
import '../controllers/auth_controller.dart';
import '../../../../core/routing/app_page.dart';

class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    // Nasłuchujemy danych użytkownika, aby wydobyć język
    final userState = ref.watch(userControllerProvider); 
    
    final bool isLoggedIn = authState.isAuthenticated;

    // --- STAN: ZALOGOWANY (Menu Popup) ---
    if (isLoggedIn) {
      // Wyciągamy język z globalnego stanu (jeśli jest załadowany)
      final String? langCode = userState.valueOrNull?.profile?.nativeLanguage;

      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: PopupMenuButton<String>(
          offset: const Offset(0, 50),
          tooltip: 'User menu',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

          constraints: const BoxConstraints(minWidth: 170),
          
          // ================= ZMIANA: WIDGET BADGE Z FLAGĄ =================
          icon: Badge(
            // Wyrównanie do prawego dolnego rogu
            alignment: Alignment.bottomRight,
            // Delikatne przesunięcie, by flaga częściowo wystawała za avatar
            offset: const Offset(4, -12),
            // Białe tło pod flagą tworzy elegancki "cutout" (wycięcie)
            backgroundColor: Colors.white,
            
            // Tworzymy cień i padding dla flagi
            label: Text(
              AppLanguages.getFlag(langCode ?? '--'), // Zabezpieczenie na null
              style: const TextStyle(fontSize: 10, height: 1.1),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.person, color: Colors.deepPurple, size: 20),
            ),
          ),
          // =================================================================
          
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout(context, ref);
            } else if (value == 'settings') {
              ref.read(navigationProvider.notifier).state = AppPage.settings;
            }
          },
          
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                // Wyświetlamy też login użytkownika w menu dla lepszego UX!
                userState.valueOrNull?.username ?? "My Account", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
            ),

            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.black87, size: 20),
                  SizedBox(width: 12),
                  Text('Settings', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Log out', style: TextStyle(color: Colors.black87)),
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
        tooltip: "Log in",
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.login, color: Colors.grey.shade700, size: 20),
        ),
        onPressed: () {
          ref.read(navigationProvider.notifier).state = AppPage.login;
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    ref.read(navigationProvider.notifier).state = AppPage.home;
  }
}