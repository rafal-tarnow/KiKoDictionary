import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/widgets/user_avatar_button.dart';
import 'controllers/project_tasks_controller.dart';
import 'controllers/projects_controller.dart';
import 'controllers/projects_session_provider.dart';
import 'controllers/selected_project_provider.dart';
import 'project_actions.dart';
import 'projects_ui.dart';
import 'widgets/item_actions_menu.dart';

/// AppBar strony Projects: na liście tytuł "Projects", w projekcie - strzałka
/// powrotu, nazwa projektu i akcje (edycja / usunięcie projektu).
class ProjectsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ProjectsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(projectsSessionProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final project = selectedProjectId == null
        ? null
        : ref.watch(projectsControllerProvider.select((s) => s.findById(selectedProjectId)));

    if (!isLoggedIn || selectedProjectId == null) {
      final isLoading = ref.watch(projectsControllerProvider.select((s) => s.isLoading));
      return AppBar(
        title: const Text("Projects"),
        elevation: 2,
        actions: [
          if (isLoggedIn)
            _RefreshButton(
              isLoading: isLoading,
              onPressed: ref.read(projectsControllerProvider.notifier).loadProjects,
            ),
          const UserAvatarButton(),
        ],
      );
    }

    final isLoading = ref.watch(projectTasksControllerProvider(selectedProjectId).select((s) => s.isLoading));
    return AppBar(
      elevation: 2,
      leading: BackButton(
        onPressed: () => ref.read(selectedProjectIdProvider.notifier).state = null,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          if (project != null) ...[
            Icon(Icons.folder, color: project.displayColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(project?.name ?? "Project", overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        _RefreshButton(
          isLoading: isLoading,
          onPressed: ref.read(projectTasksControllerProvider(selectedProjectId).notifier).loadTasks,
        ),
        if (project != null)
          ItemActionsMenu(
            iconColor: Colors.black87,
            onEdit: () => ProjectActions.edit(context, ref, project),
            onDelete: () => ProjectActions.delete(context, ref, project),
          ),
        const UserAvatarButton(),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RefreshButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Refresh",
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
            )
          : const Icon(Icons.refresh),
    );
  }
}
