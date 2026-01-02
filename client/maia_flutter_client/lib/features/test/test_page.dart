import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/features/test/backend/backend_provider.dart';

class TestPage extends ConsumerWidget{
  const TestPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final brickName = ref.watch(testBackendProvider.select((testBackend) => testBackend.brickName));
    final bricksCount = ref.watch(testBackendProvider.select((testBackend) => testBackend.bricksCount));
    final brickStatus = ref.watch(testBackendProvider.select((testBackend) => testBackend.brickStatus));

    return Center(
      // Teraz możesz użyć zmiennej brickName bezpośrednio
      child: Column(
        children: [
          Text('Sentences page: $brickName'),
          Text('Bricks count: $bricksCount'),
          Icon(
            brickStatus ? Icons.check_circle : Icons.error,
            color: brickStatus ? Colors.green : Colors.red,
            size: 24,
            ),
        ],
      ),
    );
  }
}