import 'package:flutter/material.dart';
import '../../core/widgets/main_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      body: Center(child: Text('Strona Główna - Nauka Angielskiego')),
    );
  }
}