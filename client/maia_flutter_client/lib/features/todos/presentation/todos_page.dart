import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../core/navigation_provider.dart';
import '../../../core/routing/app_page.dart';
import 'todos_provider.dart';
import 'widgets/todo_card.dart';
import 'widgets/todo_dialog.dart';

class TodosPage extends ConsumerWidget {
  const TodosPage({super.key});

  // ================= [DODANE]: Okienko zachęty do logowania (Spójne z Sentences) =================
  void _showLoginPrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.checklist_rtl,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Plan your learning!",
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Log in or create a free account to manage your daily tasks in English and immerse yourself in the language.",
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(navigationProvider.notifier).state = AppPage.register;
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("CREATE ACCOUNT"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(navigationProvider.notifier).state = AppPage.login;
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.deepPurple.shade200),
                        foregroundColor: Colors.deepPurple.shade700,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("LOG IN"),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade500),
                    child: const Text("Maybe later"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ==============================================================================================

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

    // ================= [DODANE]: Sprawdzanie czy zalogowany =================
    final isLoggedIn = ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isLoggedIn) {
            _showAddDialog(context, ref);
          } else {
            _showLoginPrompt(context, ref);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("ADD TASK"),
      ),

      body: Column(
        children: [
          // Pasek błędów API (Tylko jeśli zalogowany)
          if (isLoggedIn && state.error != null)
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
            child: (!isLoggedIn)
                // ================= [DODANE]: WIDOK DLA NIEZALOGOWANEGO =================
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 72,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Daily tasks in English",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Create your daily to-do lists in English. It's the best way to immerse yourself in the language every day!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  )
                // =======================================================================
                : state.isLoading && state.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.items.isEmpty
                        ? _buildEmptyState() 
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
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80), 
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        notifier.reorder(oldIndex, newIndex);
      },
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