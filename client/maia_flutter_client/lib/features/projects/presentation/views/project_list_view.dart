import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/projects_controller.dart';
import '../controllers/selected_project_provider.dart';
import '../project_actions.dart';
import '../projects_ui.dart';
import '../widgets/project_card.dart';
import '../widgets/projects_status_views.dart';

/// Poziom 1: lista projektów użytkownika (przeciągalna).
class ProjectListView extends ConsumerWidget {
  const ProjectListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectsControllerProvider);
    final controller = ref.read(projectsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'projects_list_fab',
        onPressed: () => ProjectActions.create(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text("NEW PROJECT"),
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            ProjectsErrorBanner(message: state.errorMessage!, onRetry: controller.loadProjects),
          if (state.isLoading && state.projects.isNotEmpty) const LinearProgressIndicator(minHeight: 3),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectsState state) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.projects.isEmpty) {
      return const ProjectsEmptyState(
        icon: Icons.create_new_folder_outlined,
        title: "You don't have any projects yet.",
        message: "Create a project to group related tasks - e.g. \"Exam preparation\" or \"Daily vocabulary\".",
      );
    }

    final controller = ref.read(projectsControllerProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.loadProjects,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 88), // odstęp na FAB
        itemCount: state.projects.length,
        buildDefaultDragHandles: false,
        proxyDecorator: projectsDragProxyDecorator,
        onReorderItem: (oldIndex, newIndex) async {
          final result = await controller.reorderProjects(oldIndex, newIndex);
          if (context.mounted) ProjectsUi.showFailure(context, result);
        },
        itemBuilder: (context, index) {
          final project = state.projects[index];
          // Długie przytrzymanie karty = przeciąganie na ekranach dotykowych
          return ReorderableDelayedDragStartListener(
            key: ValueKey(project.id),
            index: index,
            child: ProjectCard(
              project: project,
              index: index,
              onOpen: () => ref.read(selectedProjectIdProvider.notifier).state = project.id,
              onEdit: () => ProjectActions.edit(context, ref, project),
              onDelete: () => ProjectActions.delete(context, ref, project),
            ),
          );
        },
      ),
    );
  }
}
