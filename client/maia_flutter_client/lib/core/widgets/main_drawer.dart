import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "../../features/auth/presentation/auth_controller.dart";
import '../navigation_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    // Obserwujemy stan autentykacji
    final authState = ref.watch(authControllerProvider);
    final isLoggedIn = authState.isAuthenticated;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'English Learner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoggedIn ? 'Witaj, użytkowniku!' : 'Tryb Gościa',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Twój postęp: 45%',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _DrawerTile(
            title: 'Ogłoszenia parafialne',
            icon: Icons.home,
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _DrawerTile(
            title: 'Slownik',
            icon: Icons.menu_book,
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _DrawerTile(
            title: 'Slowka',
            icon: Icons.school,
            index: 2,
            isSelected: selectedIndex == 2,
          ),
          _DrawerTile(
            title: 'Zwroty',
            icon: Icons.chat,
            index: 3,
            isSelected: selectedIndex == 3,
          ),
          _DrawerTile(
            title: 'Rejestracja',
            icon: Icons.chat,
            index: 4,
            isSelected: selectedIndex == 4,
          ),
          _DrawerTile(
            title: 'Logowanie',
            icon: Icons.login,
            index: 5,
            isSelected: selectedIndex == 5,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              "DEV TOOLS",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          _DrawerTile(
            title: 'Test',
            icon: Icons.quiz,
            index: 6,
            isSelected: selectedIndex == 6,
          ),
          _DrawerTile(
            title: 'Health Check',
            icon: Icons.dns,
            index: 7,
            isSelected: selectedIndex == 7,
          ),
          _DrawerTile(
            title: 'Captcha Test',
            icon: Icons.security,
            index: 8,
            isSelected: selectedIndex == 8,
          ),
        ],
      ),
    );
  }
}

// _DrawerTile pozostaje bez zmian jak w Twoim pliku
class _DrawerTile extends ConsumerWidget {
  final String title;
  final IconData icon;
  final int index;
  final bool isSelected;

  const _DrawerTile({
    required this.title,
    required this.icon,
    required this.index,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepPurple : null),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.deepPurple : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
        Navigator.pop(context);
      },
    );
  }
}
