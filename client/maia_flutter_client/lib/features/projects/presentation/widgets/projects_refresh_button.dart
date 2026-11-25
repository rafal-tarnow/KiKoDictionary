import 'package:flutter/material.dart';

/// Przycisk "Odśwież" w AppBarze - w trakcie ładowania pokazuje kółko i jest nieaktywny.
class ProjectsRefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const ProjectsRefreshButton({super.key, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Refresh",
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
            )
          : const Icon(Icons.refresh),
    );
  }
}
