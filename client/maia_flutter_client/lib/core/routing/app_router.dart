import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/captcha/captcha_routes.dart';
import '../../features/dictionary/dictionary_routes.dart';
import '../../features/home/home_routes.dart';
import '../../features/projects/projects_routes.dart';
import '../../features/sentences/sentences_routes.dart';
import '../../features/settings/settings_routes.dart';
import '../../features/test/test_routes.dart';
import '../../features/todos/todos_routes.dart';
import '../../features/user/presentation/controllers/user_controller.dart';
import '../../features/words/words_routes.dart';
import '../widgets/not_found_page.dart';
import 'route_access.dart';

/// Reguły dostępu do stron - ścieżki pochodzą z plików `*_routes.dart` modułów.
final routeAccessRules = RouteAccessRules(
  homePath: HomeRoutes.homePath,
  loginPath: AuthRoutes.loginPath,
  onboardingPath: AuthRoutes.onboardingPath,
  guestOnlyPaths: AuthRoutes.guestOnlyPaths,
  loginRequiredPaths: [
    SettingsRoutes.settingsPath,
    '${ProjectsRoutes.listPath}/', // szczegóły projektu; sama lista ma widok dla gościa
  ],
);

/// Router aplikacji - jedno miejsce, które składa trasy wszystkich modułów.
///
/// Sekcje z Drawera to gałęzie [StatefulShellRoute.indexedStack]: każda ma własny stos
/// stron i zachowuje stan (przewinięcie, numer strony listy) przy przełączaniu,
/// a buduje się dopiero przy pierwszym wejściu. Logowanie i onboarding są poza gałęziami.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  final router = GoRouter(
    initialLocation: HomeRoutes.homePath,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRouteRedirect(
      auth: _authSnapshot(ref),
      location: state.uri,
      rules: routeAccessRules,
    ),
    errorBuilder: (context, state) => NotFoundPage(location: state.uri.toString()),
    routes: [
      ...AuthRoutes.routes(),
      StatefulShellRoute.indexedStack(
        // Ramę (szerokość, tło) daje AppFrame w MaterialApp.router; AppBar i Drawer - każda strona sama
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          HomeRoutes.branch(),
          WordsRoutes.branch(),
          ...SentencesRoutes.branches(),
          TodosRoutes.branch(),
          ProjectsRoutes.branch(),
          SettingsRoutes.branch(),
          DictionaryRoutes.branch(),
          TestRoutes.branch(),
          CaptchaRoutes.branch(),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

RouteAuthSnapshot _authSnapshot(Ref ref) {
  final auth = ref.read(authControllerProvider);
  final profile = ref.read(userControllerProvider).valueOrNull?.profile;
  return RouteAuthSnapshot(
    isCheckingSession: auth.isAppLoading,
    isAuthenticated: auth.isAuthenticated,
    needsOnboarding: profile == null ? null : !profile.isOnboardingCompleted,
  );
}

/// Most Riverpod -> go_router: gdy zmienia się sesja albo profil (np. onboarding),
/// router ponownie sprawdza `redirect` dla bieżącej strony.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(userControllerProvider, (_, _) => notifyListeners());
  }
}
