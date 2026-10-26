import 'package:flutter/material.dart';

/// Czerwony pasek błędu z przyciskiem ponowienia (jak na stronie Sentences).
class ProjectsErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProjectsErrorBanner({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade900)),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: Colors.red.shade900),
            label: Text("Retry", style: TextStyle(color: Colors.red.shade900)),
          ),
        ],
      ),
    );
  }
}

/// Pusty stan listy: duża ikona, tytuł i podpowiedź.
class ProjectsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ProjectsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.deepPurple.shade100),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cień podnoszonego elementu podczas przeciągania (jak w Daily Tasks).
Widget projectsDragProxyDecorator(Widget child, int index, Animation<double> animation) {
  return Material(elevation: 6, color: Colors.transparent, child: child);
}
