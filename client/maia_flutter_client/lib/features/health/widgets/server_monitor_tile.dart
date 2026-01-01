import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../server_health_provider.dart';

class ServerMonitorTile extends ConsumerWidget {
  final String serverUrl;
  final String serviceName;

  const ServerMonitorTile({
    super.key,
    required this.serverUrl,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obserwujemy stan dla konkretnego URL-a
    final healthState = ref.watch(serverHealthProvider(serverUrl));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Ikona statusu (zamiast Rectangle z QML)
            _buildStatusIndicator(healthState),
            
            const SizedBox(width: 16),
            
            // Tekst
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    serverUrl,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Przycisk odświeżania (opcjonalnie)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: () {
                // Wymusza ponowne pobranie danych dla tego URL
                ref.invalidate(serverHealthProvider(serverUrl));
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(AsyncValue<ServerStatus> state) {
    return state.when(
      data: (status) {
        final color = status == ServerStatus.online ? Colors.green : Colors.red;
        final icon = status == ServerStatus.online ? Icons.check_circle : Icons.error;
        return Icon(icon, color: color, size: 24);
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error, color: Colors.red, size: 24),
    );
  }
}