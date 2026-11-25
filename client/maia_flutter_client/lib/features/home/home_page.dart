import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Home",
      actions: [
        IconButton(icon: const Icon(Icons.notifications), tooltip: "Notifications", onPressed: () {}),
      ],
      body: const Center(child: Text('Home Page - Learning English')),
    );
  }
}
