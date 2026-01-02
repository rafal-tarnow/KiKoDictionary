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
    // Obserwujemy StreamProvidera
    final AsyncValue<bool> healthState = ref.watch(serverHealthProvider(serverUrl));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Ikona statusu z obsługą ładowania
            _buildStatusIndicator(healthState),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    serverUrl,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(AsyncValue<bool> state) {
    return state.when(
      // Gdy mamy dane (true/false)
      data: (isAlive) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isAlive ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAlive ? Icons.check : Icons.close,
            color: Colors.white,
            size: 16,
          ),
        );
      },
      // Gdy się ładuje (pierwsze zapytanie)
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      // Gdy wystąpi błąd w samym Streamie (rzadkie przy try-catch w serwisie)
      error: (_, __) => const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}