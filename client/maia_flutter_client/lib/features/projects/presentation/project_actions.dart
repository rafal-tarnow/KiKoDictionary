import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/project.dart';
import 'controllers/projects_controller.dart';
import 'projects_ui.dart';
import 'widgets/confirm_delete_dialog.dart';
import 'widgets/project_form_dialog.dart';

/// Akcje na projekcie wywoływane z kilku miejsc (lista, AppBar szczegółów).
/// Łączą dialog -> kontroler -> komunikat błędu, żeby widoki zostały cienkie.
abstract final class ProjectActions {
  static Future<void> create(BuildContext context, WidgetRef ref) async {
    final draft = await ProjectFormDialog.show(context);
    if (draft == null || !context.mounted) return;

    final result = await ref.read(projectsControllerProvider.notifier).createProject(draft);
    if (context.mounted) ProjectsUi.showFailure(context, result);
  }

  static Future<void> edit(BuildContext context, WidgetRef ref, Project project) async {
    final draft = await ProjectFormDialog.show(context, project: project);
    if (draft == null || !context.mounted) return;

    final result = await ref.read(projectsControllerProvider.notifier).updateProject(project.id, draft);
    if (context.mounted) ProjectsUi.showFailure(context, result);
  }

  /// [onConfirmed] wywoływane po potwierdzeniu, przed usunięciem - np. strona szczegółów
  /// wraca wtedy do listy, żeby nie pokazywać znikającego projektu.
  static Future<void> delete(
    BuildContext context,
    WidgetRef ref,
    Project project, {
    VoidCallback? onConfirmed,
  }) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: "Delete Project",
      message: project.taskCount == 0
          ? "Are you sure you want to delete \"${project.name}\"?"
          : "Are you sure you want to delete \"${project.name}\" and all its ${project.taskCount} tasks?",
    );
    if (!confirmed || !context.mounted) return;

    // Zależności pobieramy PRZED onConfirmed: po przejściu do listy ta strona (i jej ref) znika
    final controller = ref.read(projectsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    onConfirmed?.call();

    final result = await controller.deleteProject(project.id);
    ProjectsUi.showFailureOn(messenger, result);
  }
}
