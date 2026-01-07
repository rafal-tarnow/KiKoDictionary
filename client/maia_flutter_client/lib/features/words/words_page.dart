import 'package:flutter/material.dart';
import '../../core/widgets/main_drawer.dart';

class WordsPage extends StatelessWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      drawer: const MainDrawer(),
      body: Center(child: Text('Nauka slowek - niebawem')),
    );
  }
}
