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
            icon: Icons.style,
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _DrawerTile(
            title: 'Slowka',
            icon: Icons.person,
            index: 2,
            isSelected: selectedIndex == 2,
          ),
          _DrawerTile(
            title: 'Zwroty',
            icon: Icons.settings,
            index: 3,
            isSelected: selectedIndex == 3,
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