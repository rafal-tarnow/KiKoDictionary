import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todos_provider.dart';
import 'widgets/todo_card.dart';
import 'widgets/todo_dialog.dart';

class TodosPage extends ConsumerWidget {
  const TodosPage({super.key});

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const TodoDialog(),
    );

    if (result != null && result.isNotEmpty) {
      final success = await ref.read(todosProvider.notifier).addTodo(result);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add task")),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, int id, String currentContent) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => TodoDialog(initialContent: currentContent),
    );

    if (result != null && result.isNotEmpty && result != currentContent) {
      final success = await ref.read(todosProvider.notifier).updateContent(id, result);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update task")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todosProvider);
    final notifier = ref.read(todosProvider.notifier);

    // ================= BUDOWA LAYOUTU =================
    return Scaffold(
      backgroundColor: Colors.transparent, // Tło dziedziczy z MainShell (E0E0E0)
      
      // Pływający przycisk spójny z językiem Material Design 3
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text("ADD TASK"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // Pasek błędów API
          if (state.error != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                    ? _buildEmptyState() // Ekran pusty
                    : _buildReorderableList(state.items, notifier, context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Your task list is empty.",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Add daily tasks in English to immerse yourself in the language!",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(List items, TodosController notifier, BuildContext context, WidgetRef ref) {
    // ReorderableListView pozwala na Drag & Drop "out-of-the-box"
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80), // Miejsce pod Fabem
      itemCount: items.length,
      // Wywoływane, gdy puścimy element
      onReorder: (oldIndex, newIndex) {
        notifier.reorder(oldIndex, newIndex);
      },
      // Dodajemy małe ułatwienie UX, aby lista wyglądała ładnie podczas chwytania
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          elevation: 6,
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final todo = items[index];
        return TodoCard(
          // KRYTYCZNE W REORDERABLE LIST: Każdy element MUSI mieć unikalny Key.
          key: ValueKey(todo.id), 
          todo: todo,
          onToggle: () => notifier.toggleCompleted(todo),
          onEdit: () => _showEditDialog(context, ref, todo.id, todo.content),
          onDelete: () => notifier.deleteTodo(todo.id),
        );
      },
    );
  }
}