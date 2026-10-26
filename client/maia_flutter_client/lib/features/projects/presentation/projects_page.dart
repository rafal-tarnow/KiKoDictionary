import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation_provider.dart';
import '../../../core/routing/app_page.dart';
import 'controllers/projects_session_provider.dart';
import 'controllers/selected_project_provider.dart';
import 'views/project_details_view.dart';
import 'views/project_list_view.dart';
import 'widgets/projects_guest_view.dart';

/// Punkt wejścia modułu Projects (pozycja w Drawerze).
///
/// Przełącza widok listy projektów i szczegółów projektu na podstawie
/// [selectedProjectIdProvider]. Systemowy "wstecz" wraca do listy.
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(projectsSessionProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    // Strony żyją w IndexedStack - przechwytujemy "wstecz" tylko gdy ta strona jest widoczna
    final isActivePage = ref.watch(navigationProvider) == AppPage.projects;

    if (!isLoggedIn) return const ProjectsGuestView();

    return PopScope(
      canPop: !(isActivePage && selectedProjectId != null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(selectedProjectIdProvider.notifier).state = null;
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selectedProjectId == null
            ? const ProjectListView(key: ValueKey('projects_list'))
            : ProjectDetailsView(
                key: ValueKey('project_$selectedProjectId'),
                projectId: selectedProjectId,
              ),
      ),
    );
  }
}
