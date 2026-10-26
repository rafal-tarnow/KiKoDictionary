import 'package:flutter/material.dart';
import '../../data/models/project.dart';
import '../projects_ui.dart';
import 'item_actions_menu.dart';

/// Karta projektu na liście. Przeciąganie: uchwyt po lewej (mysz) lub długie
/// przytrzymanie całej karty (dotyk) - obsługuje `ReorderableListView`.
class ProjectCard extends StatelessWidget {
  final Project project;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.index,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = project.displayColor;
    final isDone = project.taskCount > 0 && project.completedTaskCount == project.taskCount;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: onOpen,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pasek w kolorze projektu
              Container(width: 6, color: color),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_indicator, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(isDone ? Icons.task_alt : Icons.folder, color: color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (project.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          project.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _ProgressRow(project: project, color: color),
                    ],
                  ),
                ),
              ),
              Center(child: ItemActionsMenu(onEdit: onEdit, onDelete: onDelete)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final Project project;
  final Color color;

  const _ProgressRow({required this.project, required this.color});

  @override
  Widget build(BuildContext context) {
    if (project.taskCount == 0) {
      return Text("No tasks yet", style: TextStyle(fontSize: 12, color: Colors.grey.shade500));
    }
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "${project.completedTaskCount}/${project.taskCount}",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
