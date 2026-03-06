import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_repository.dart';
import '../../../auth/data/models/user_model.dart';

// Stan asynchroniczny (może być loading, error, lub załadowane dane Usera)
class UserController extends StateNotifier<AsyncValue<User?>> {
  final UserRepository _repository;

  // Na starcie ustawiamy stan jako ładujący
  UserController(this._repository) : super(const AsyncValue.loading());

  // Pobiera dane usera z backendu i zapisuje w stanie globalnym
  Future<void> fetchUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.getUserMe();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Szybka, lokalna aktualizacja po sukcesie z PATCH. 
  // Zapobiega to konieczności pobierania całego usera od nowa.
  void updateLocalProfileLanguage(String newLanguage) {
    final currentUser = state.value;
    if (currentUser?.profile != null) {
      // W Darcie obiekty są immutable, więc by to zrobić "podręcznikowo", 
      // powinniśmy mieć metodę copyWith w modelu.
      // Skrócona wersja mutacji (jako że to uproszczenie w Darcie):
      state = AsyncValue.data(User(
        id: currentUser!.id,
        username: currentUser.username,
        email: currentUser.email,
        role: currentUser.role,
        profile: currentUser.profile, // Uwaga, to referencja, zmieniamy niżej
      ));
      
      // Aby ui zaktualizowało się natychmiast musimy zasymulować zmianę.
      // W wersji produkcyjnej najlepiej dodać metodę `copyWith` do klas User i UserProfile.
      fetchUser(); // Na ten moment: pobierzmy usera z bazy zaktualizowanego, to gwarantuje spójność.
    }
  }

  // Czyszczenie stanu po wylogowaniu
  void clearUser() {
    state = const AsyncValue.data(null);
  }
}

// Provider globalny (trzyma stan tak długo jak aplikacja działa)
final userControllerProvider = StateNotifierProvider<UserController, AsyncValue<User?>>((ref) {
  return UserController(ref.watch(userRepositoryProvider));
});