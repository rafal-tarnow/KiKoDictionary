import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project.dart';
import '../../data/models/project_task.dart';
import '../controllers/project_tasks_controller.dart';
import '../controllers/projects_controller.dart';
import '../projects_ui.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/project_task_card.dart';
import '../widgets/projects_status_views.dart';
import '../widgets/task_form_dialog.dart';

/// Poziom 2: zadania wybranego projektu (przeciągalne).
class ProjectDetailsView extends ConsumerWidget {
  final int projectId;

  const ProjectDetailsView({super.key, required this.projectId});

  ProjectTasksController _controller(WidgetRef ref) =>
      ref.read(projectTasksControllerProvider(projectId).notifier);

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final draft = await TaskFormDialog.show(context);
    if (draft == null || !context.mounted) return;
    final result = await _controller(ref).createTask(draft);
    if (context.mounted) ProjectsUi.showFailure(context, result);
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref, ProjectTask task) async {
    final draft = await TaskFormDialog.show(context, task: task);
    if (draft == null || !context.mounted) return;
    final result = await _controller(ref).updateTask(task.id, draft);
    if (context.mounted) ProjectsUi.showFailure(context, result);
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref, ProjectTask task) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: "Delete Task",
      message: "Are you sure you want to delete \"${task.title}\"?",
    );
    if (!confirmed || !context.mounted) return;
    final result = await _controller(ref).deleteTask(task.id);
    if (context.mounted) ProjectsUi.showFailure(context, result);
  }

  Future<void> _toggleTask(BuildContext context, WidgetRef ref, ProjectTask task) async {
    final result = await _controller(ref).toggleCompleted(task);
    if (context.mounted) ProjectsUi.showFailure(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectTasksControllerProvider(projectId));
    final project = ref.watch(projectsControllerProvider.select((s) => s.findById(projectId)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'project_details_fab',
        onPressed: () => _addTask(context, ref),
        icon: const Icon(Icons.add),
        label: const Text("ADD TASK"),
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            ProjectsErrorBanner(message: state.errorMessage!, onRetry: _controller(ref).loadTasks),
          if (state.isLoading && state.tasks.isNotEmpty) const LinearProgressIndicator(minHeight: 3),
          Expanded(child: _buildBody(context, ref, state, project)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectTasksState state, Project? project) {
    if (state.isLoading && state.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final header = project == null
        ? null
        : _ProjectSummaryHeader(
            project: project,
            total: state.tasks.length,
            completed: state.completedCount,
          );
    if (state.tasks.isEmpty) {
      return Column(
        children: [
          ?header,
          const Expanded(
            child: ProjectsEmptyState(
              icon: Icons.playlist_add,
              title: "This project has no tasks yet.",
              message: "Break your goal into small steps and add them with the button below.",
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _controller(ref).loadTasks,
      child: ReorderableListView.builder(
        header: header,
        padding: const EdgeInsets.only(bottom: 88), // odstęp na FAB
        itemCount: state.tasks.length,
        buildDefaultDragHandles: false,
        proxyDecorator: projectsDragProxyDecorator,
        onReorderItem: (oldIndex, newIndex) async {
          final result = await _controller(ref).reorderTasks(oldIndex, newIndex);
          if (context.mounted) ProjectsUi.showFailure(context, result);
        },
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(task.id),
            index: index,
            child: ProjectTaskCard(
              task: task,
              index: index,
              onToggle: () => _toggleTask(context, ref, task),
              onEdit: () => _editTask(context, ref, task),
              onDelete: () => _deleteTask(context, ref, task),
            ),
          );
        },
      ),
    );
  }
}

/// Opis projektu i pasek postępu nad listą zadań.
/// Liczniki pochodzą z aktualnej listy zadań (źródło prawdy w tym widoku).
class _ProjectSummaryHeader extends StatelessWidget {
  final Project project;
  final int total;
  final int completed;

  const _ProjectSummaryHeader({required this.project, required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final color = project.displayColor;
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.description != null) ...[
            Text(project.description!, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                total == 0 ? "No tasks" : "$completed of $total done · $percent%",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
