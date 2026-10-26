import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Jedyny punkt styku modułu Projects z modułem Auth.
///
/// Kontrolery obserwują ten provider, więc same ładują dane po zalogowaniu
/// i czyszczą je po wylogowaniu - bez zmian w `AuthController`.
/// W testach wystarczy go nadpisać (`overrideWith`).
final projectsSessionProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider.select((state) => state.isAuthenticated));
});
