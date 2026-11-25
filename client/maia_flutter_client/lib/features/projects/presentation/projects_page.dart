import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/projects_session_provider.dart';
import 'views/project_list_view.dart';
import 'widgets/projects_guest_view.dart';

/// Strona `/projects`: lista projektów zalogowanego użytkownika albo zajawka dla gościa.
/// Szczegóły projektu to osobna trasa `/projects/:projectId` (patrz projects_routes.dart).
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(projectsSessionProvider);
    return isLoggedIn ? const ProjectListView() : const ProjectsGuestView();
  }
}
