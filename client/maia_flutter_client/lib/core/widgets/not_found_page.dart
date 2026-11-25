import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_scaffold.dart';

/// Strona dla nieznanego adresu (np. literówka w linku).
class NotFoundPage extends StatelessWidget {
  final String location;

  const NotFoundPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Page not found",
      // Strona błędu nie leży w żadnej gałęzi Drawera - nawigujemy przyciskiem poniżej
      showDrawer: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore, size: 72, color: Colors.deepPurple.shade100),
              const SizedBox(height: 16),
              const Text(
                "This page doesn't exist.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(location, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text("GO TO HOME"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
