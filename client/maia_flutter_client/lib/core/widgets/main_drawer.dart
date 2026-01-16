import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Odczytujemy stan, żeby wiedzieć, który element podświetlić
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'English Learner',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
            title: 'Test',
            icon: Icons.quiz,
            index: 5,
            isSelected: selectedIndex == 5,
          ),
          _DrawerTile(
            title: 'Health Check',
            icon: Icons.dns,
            index: 6,
            isSelected: selectedIndex == 6
          ),
          _DrawerTile(
            title: 'Captcha Test', 
            icon: Icons.security, 
            index: 7,
            isSelected: selectedIndex == 7
          ),
        ],
      ),
    );
  }
}

// Prywatny pomocniczy widget tylko dla tego pliku (Clean Code)
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
      title: Text(title),
      selected: isSelected,
      onTap: () {
        // 1. Zmień stan indeksu
        ref.read(navigationIndexProvider.notifier).state = index;
        // 2. Zamknij drawer (ekran boczny)
        Navigator.pop(context);
      },
    );
  }
}