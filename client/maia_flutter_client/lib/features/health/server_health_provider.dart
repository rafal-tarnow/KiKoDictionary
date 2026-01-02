import 'package:flutter_riverpod/flutter_riverpod.dart';
import './services/health_check_service.dart';

final healthCheckServiceProvider = Provider((ref) => HealthCheckService());

// StreamProvider automatycznie obsługuje stan Loading/Error/Data
// .family pozwala przekazać URL
final serverHealthProvider = StreamProvider.autoDispose.family<bool, String>((ref, url) async* {
  final service = ref.watch(healthCheckServiceProvider);

  // 1. Sprawdź natychmiast przy starcie
  yield await service.checkHost(url);

  // 2. Uruchom pętlę (Timer) - co 5 sekund (jak w C++ interval)
  // Stream.periodic działa jak QTimer
  final stream = Stream.periodic(const Duration(seconds: 5), (_) {
    return service.checkHost(url);
  });

  // 3. Emituj wyniki z pętli
  await for (final isAlive in stream) {
    yield await isAlive; // await tutaj, bo checkHost zwraca Future
  }
});