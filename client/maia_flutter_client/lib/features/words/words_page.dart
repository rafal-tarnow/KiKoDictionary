import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';

class WordsPage extends StatelessWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: "Words",
      body: Center(child: Text('Vocabulary Learning - Coming Soon')),
    );
  }
}
