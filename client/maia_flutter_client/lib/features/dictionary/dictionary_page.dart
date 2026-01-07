import 'package:flutter/material.dart';
import '../../core/widgets/main_drawer.dart';

class DictionaryPage extends StatelessWidget{
  const DictionaryPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
    );
  }
}