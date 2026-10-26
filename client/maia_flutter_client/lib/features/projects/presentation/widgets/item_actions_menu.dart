import 'package:flutter/material.dart';

enum _ItemAction { edit, delete }

/// Menu "⋮" z akcjami Edit / Delete (wygląd jak w Daily Tasks).
class ItemActionsMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color? iconColor;

  const ItemActionsMenu({super.key, required this.onEdit, required this.onDelete, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ItemAction>(
      tooltip: 'More actions',
      icon: Icon(Icons.more_vert, color: iconColor ?? Colors.grey),
      onSelected: (action) => switch (action) {
        _ItemAction.edit => onEdit(),
        _ItemAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ItemAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 12),
              Text("Edit"),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ItemAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 12),
              Text("Delete", style: TextStyle(color: Colors.red.shade700)),
            ],
          ),
        ),
      ],
    );
  }
}
