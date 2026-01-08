import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/features/test/backend/backend_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../core/widgets/main_drawer.dart';

class TestPage extends ConsumerWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brickName = ref.watch(
      testBackendProvider.select((testBackend) => testBackend.brickName),
    );
    final bricksCount = ref.watch(
      testBackendProvider.select((testBackend) => testBackend.bricksCount),
    );
    final brickStatus = ref.watch(
      testBackendProvider.select((testBackend) => testBackend.brickStatus),
    );

    return Scaffold(
      body: Column(
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
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,

        renderOverlay: false,
        //overlayColor: Colors.black,
        //overlayOpacity: 0.3,

        closeManually: false,
        children: [
          SpeedDialChild(
            child: Icon(Icons.refresh),
            label: 'Odśwież',
            onTap: (){
              _showShackBar(context, 'Odświeżono');
            }
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Dodaj zwrot',
          ),
        ],
      ),
    );
  }

  void _showShackBar(BuildContext context, String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 500),)
    );
  }
}
