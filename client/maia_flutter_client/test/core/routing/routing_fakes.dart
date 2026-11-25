import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/features/auth/data/models/user_model.dart';
import 'package:maia_flutter_client/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maia_flutter_client/features/user/data/models/user_profile_model.dart';
import 'package:maia_flutter_client/features/user/presentation/controllers/user_controller.dart';

/// Sesja sterowana z testu (bez prawdziwego storage i sieci).
class FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  FakeAuthController({bool loggedIn = false, bool checkingSession = false})
      : super(AuthState(isAuthenticated: loggedIn, isAppLoading: checkingSession));

  void setLoggedIn(bool value) => state = AuthState(isAuthenticated: value, isAppLoading: false);

  @override
  Future<void> checkAuthStatus() async {}

  @override
  void setAuthenticated(bool isAuthenticated) => setLoggedIn(isAuthenticated);

  @override
  Future<void> logout() async => setLoggedIn(false);
}

/// Profil użytkownika sterowany z testu (flaga onboardingu).
class FakeUserController extends StateNotifier<AsyncValue<User?>> implements UserController {
  FakeUserController([User? user]) : super(AsyncValue.data(user));

  void setUser(User? user) => state = AsyncValue.data(user);

  @override
  Future<void> fetchUser() async {}

  @override
  void updateLocalProfileLanguage(String newLanguage) {}

  @override
  void clearUser() => state = const AsyncValue.data(null);
}

User testUser({bool onboardingCompleted = true}) => User(
      id: 'user-1',
      username: 'tom',
      email: 'tom@example.com',
      role: 'REGULAR',
      accountSubscription: 'FREE',
      profile: UserProfile(nativeLanguage: 'pl', uiTheme: 'light', isOnboardingCompleted: onboardingCompleted),
    );
