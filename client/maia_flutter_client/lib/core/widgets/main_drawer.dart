import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/home/home_routes.dart';
import '../../features/projects/projects_routes.dart';
import '../../features/sentences/sentences_routes.dart';
import '../../features/todos/todos_routes.dart';
import '../../features/words/words_routes.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aktywna pozycja wynika z bieżącego adresu (np. /projects/5 -> "Projects")
    final location = GoRouterState.of(context).uri.path;
    final isLoggedIn = ref.watch(authControllerProvider.select((s) => s.isAuthenticated));

    _DrawerTile tile(String title, IconData icon, String routeName, String path) => _DrawerTile(
          title: title,
          icon: icon,
          routeName: routeName,
          isSelected: path == '/' ? location == '/' : location == path || location.startsWith('$path/'),
        );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'English Learner',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoggedIn ? 'Welcome!' : 'Guest Mode',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Text('Your progress: 45%', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          tile('Home', Icons.home, HomeRoutes.home, HomeRoutes.homePath),
          tile('Words', Icons.school, WordsRoutes.words, WordsRoutes.wordsPath),
          const _SectionHeader('SENTENCES'),
          tile('My Sentences', Icons.book, SentencesRoutes.mySentences, SentencesRoutes.mySentencesPath),
          tile('Community', Icons.public, SentencesRoutes.community, SentencesRoutes.communityPath),
          const _SectionHeader('TODO'),
          tile('Daily Tasks', Icons.checklist_rtl, TodosRoutes.todos, TodosRoutes.todosPath),
          const _SectionHeader('PROJECTS'),
          tile('Projects', Icons.folder_copy_outlined, ProjectsRoutes.list, ProjectsRoutes.listPath),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String routeName;
  final bool isSelected;

  const _DrawerTile({
    required this.title,
    required this.icon,
    required this.routeName,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
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
        // Najpierw zamykamy Drawer, potem przechodzimy na stronę sekcji
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.goNamed(routeName);
      },
    );
  }
}
