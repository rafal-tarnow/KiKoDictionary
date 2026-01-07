import 'package:flutter/material.dart';

class TestAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TestAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Test Page"),
      elevation: 2,
      backgroundColor: Colors.deepPurple.shade50, // Możesz stylować każdy inaczej
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}