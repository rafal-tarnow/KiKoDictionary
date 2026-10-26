import 'package:flutter/material.dart';
import '../../data/models/project_task.dart';
import '../../data/models/task_priority.dart';
import '../projects_ui.dart';
import 'item_actions_menu.dart';

/// Karta zadania w projekcie (rozwinięcie karty z Daily Tasks o notatki, priorytet i termin).
class ProjectTaskCard extends StatelessWidget {
  final ProjectTask task;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDone ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
      ),
      color: isDone ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_indicator, color: Colors.grey),
              ),
            ),
            Checkbox(
              value: isDone,
              activeColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDone ? Colors.grey.shade600 : Colors.black87,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                      if (task.priority != TaskPriority.none || task.dueDate != null) ...[
                        const SizedBox(height: 6),
                        _TaskMetaRow(task: task),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ItemActionsMenu(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _TaskMetaRow extends StatelessWidget {
  final ProjectTask task;

  const _TaskMetaRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue(DateTime.now());
    final dateColor = isOverdue ? Colors.red.shade700 : Colors.grey.shade700;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        if (task.priority != TaskPriority.none)
          _MetaLabel(
            icon: Icons.flag,
            label: task.priority.label,
            color: ProjectsUi.priorityColor(task.priority),
          ),
        if (task.dueDate != null)
          _MetaLabel(
            icon: isOverdue ? Icons.event_busy : Icons.event,
            label: ProjectsUi.formatDueDate(task.dueDate!),
            color: dateColor,
          ),
      ],
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
