import 'package:equatable/equatable.dart';

/// Stan sesji widziany przez router (bez zależności od Fluttera - łatwy do testowania).
class RouteAuthSnapshot extends Equatable {
  /// Aplikacja jeszcze sprawdza zapisany token (start) - nie przekierowujemy.
  final bool isCheckingSession;
  final bool isAuthenticated;

  /// `true` = zalogowany użytkownik nie przeszedł onboardingu,
  /// `null` = profil jeszcze się nie załadował (nie wiadomo).
  final bool? needsOnboarding;

  const RouteAuthSnapshot({
    required this.isCheckingSession,
    required this.isAuthenticated,
    this.needsOnboarding,
  });

  @override
  List<Object?> get props => [isCheckingSession, isAuthenticated, needsOnboarding];
}

/// Które ścieżki wymagają logowania, a które są tylko dla gości.
/// Ścieżki pochodzą z plików `*_routes.dart` modułów (składane w app_router.dart).
class RouteAccessRules {
  final String homePath;
  final String loginPath;
  final String onboardingPath;

  /// Strony logowania / rejestracji - zalogowany użytkownik nie ma tu czego szukać.
  final Set<String> guestOnlyPaths;

  /// Ścieżki dostępne tylko po zalogowaniu: `/settings` = ta strona i wszystko pod nią,
  /// `/projects/` (z ukośnikiem na końcu) = tylko podstrony (np. `/projects/5`), bez samej listy.
  final List<String> loginRequiredPaths;

  const RouteAccessRules({
    required this.homePath,
    required this.loginPath,
    required this.onboardingPath,
    required this.guestOnlyPaths,
    required this.loginRequiredPaths,
  });

  bool requiresLogin(String path) =>
      loginRequiredPaths.any((p) => path == p || path.startsWith(p.endsWith('/') ? p : '$p/'));
}

/// Nazwa parametru z adresem, do którego wracamy po zalogowaniu.
const String redirectAfterLoginParam = 'from';

/// Jedno miejsce decydujące o przekierowaniach (strażnik routera).
/// Zwraca nowy adres albo `null`, gdy można zostać na [location].
String? resolveRouteRedirect({
  required RouteAuthSnapshot auth,
  required Uri location,
  required RouteAccessRules rules,
}) {
  if (auth.isCheckingSession) return null;

  final path = location.path;

  if (!auth.isAuthenticated) {
    if (path == rules.onboardingPath || rules.requiresLogin(path)) {
      return Uri(path: rules.loginPath, queryParameters: {redirectAfterLoginParam: location.toString()}).toString();
    }
    return null;
  }

  // --- Zalogowany ---
  if (auth.needsOnboarding == true) {
    return path == rules.onboardingPath ? null : rules.onboardingPath;
  }
  if (path == rules.onboardingPath && auth.needsOnboarding == false) {
    return rules.homePath;
  }
  if (rules.guestOnlyPaths.contains(path)) {
    return _safeReturnLocation(location.queryParameters[redirectAfterLoginParam], rules) ?? rules.homePath;
  }
  return null;
}

/// Powrót tylko na ścieżkę wewnątrz aplikacji (bez otwartego przekierowania na obcy adres).
String? _safeReturnLocation(String? from, RouteAccessRules rules) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
  final target = Uri.tryParse(from);
  if (target == null || rules.guestOnlyPaths.contains(target.path)) return null;
  return from;
}
