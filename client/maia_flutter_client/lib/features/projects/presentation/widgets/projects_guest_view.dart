import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/auth_routes.dart';

/// Widok dla niezalogowanego użytkownika: zajawka + FAB otwierający zachętę do logowania
/// (ten sam wzorzec co w My Sentences i Daily Tasks).
class ProjectsGuestView extends StatelessWidget {
  const ProjectsGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Projects",
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'projects_guest_fab',
        onPressed: () => _showLoginPrompt(context),
        icon: const Icon(Icons.add),
        label: const Text("NEW PROJECT"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_copy_outlined, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "Projects in English",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Group your tasks into projects, set priorities and due dates - and practise English while you plan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    void goTo(BuildContext ctx, String routeName) {
      Navigator.of(ctx).pop();
      context.goNamed(routeName);
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_special_outlined, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 24),
                Text(
                  "Organise your goals!",
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Log in or create a free account to create projects and keep your tasks in sync across devices.",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => goTo(ctx, AuthRoutes.register),
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
                    onPressed: () => goTo(ctx, AuthRoutes.login),
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
      ),
    );
  }
}
