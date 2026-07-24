import 'package:flutter/material.dart';
import '../../data/models/todo_model.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Szara obwódka dla wykonanych zadań
        side: todo.isCompleted 
            ? BorderSide(color: Colors.grey.shade300) 
            : BorderSide.none,
      ),
      color: todo.isCompleted ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            // --- 1. Rączka do przeciągania (Drag Handle) ---
            ReorderableDragStartListener(
              index: -1, // To zostanie zignorowane, ReorderableListView nadpisuje, ale widgetymusimy dać "na twardo" w listach zewnętrznych, tutaj zadziała naturalnie bez tego, więc używamy natywnego IconButtona wizualnie.
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_indicator, color: Colors.grey),
              ),
            ),
            
            // --- 2. Checkbox ---
            Checkbox(
              value: todo.isCompleted,
              activeColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => onToggle(),
            ),

            // --- 3. Tekst zadania ---
            Expanded(
              child: InkWell(
                onTap: onToggle, // Kliknięcie w tekst też odhacza
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    todo.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: todo.isCompleted ? Colors.grey.shade600 : Colors.black87,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ),

            // --- 4. Menu Akcji (Edytuj / Usuń) ---
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text("Edit"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 12),
                      Text("Delete", style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}