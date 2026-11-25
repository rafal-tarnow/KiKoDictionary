import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/core/routing/app_router.dart';
import 'package:maia_flutter_client/core/routing/route_access.dart';

/// Reguły strażnika routera (czysta funkcja - bez Fluttera i bez sieci).
void main() {
  const guest = RouteAuthSnapshot(isCheckingSession: false, isAuthenticated: false);
  const user = RouteAuthSnapshot(isCheckingSession: false, isAuthenticated: true, needsOnboarding: false);
  const newUser = RouteAuthSnapshot(isCheckingSession: false, isAuthenticated: true, needsOnboarding: true);
  const userProfileLoading = RouteAuthSnapshot(isCheckingSession: false, isAuthenticated: true);
  const starting = RouteAuthSnapshot(isCheckingSession: true, isAuthenticated: false);

  String? redirect(RouteAuthSnapshot auth, String location) =>
      resolveRouteRedirect(auth: auth, location: Uri.parse(location), rules: routeAccessRules);

  group('gość', () {
    test('publiczne strony bez przekierowania (z widokiem dla gościa)', () {
      for (final path in ['/', '/sentences', '/community', '/todos', '/projects', '/login', '/register']) {
        expect(redirect(guest, path), isNull, reason: path);
      }
    });

    test('strony wymagające logowania -> /login z adresem powrotu', () {
      expect(redirect(guest, '/settings'), '/login?from=%2Fsettings');
      expect(redirect(guest, '/projects/5'), '/login?from=%2Fprojects%2F5');
      expect(redirect(guest, '/onboarding'), '/login?from=%2Fonboarding');
    });
  });

  group('zalogowany', () {
    test('strony logowania -> powrót tam, skąd przyszedł, albo Home', () {
      expect(redirect(user, '/login?from=%2Fprojects%2F5'), '/projects/5');
      expect(redirect(user, '/login'), '/');
      expect(redirect(user, '/register'), '/');
      expect(redirect(user, '/forgot-password'), '/');
    });

    test('adres powrotu nie może wyprowadzić poza aplikację', () {
      expect(redirect(user, '/login?from=https://evil.example.com'), '/');
      expect(redirect(user, '/login?from=//evil.example.com'), '/');
      expect(redirect(user, '/login?from=%2Fregister'), '/'); // bez pętli między stronami logowania
    });

    test('strony wymagające logowania są dostępne', () {
      expect(redirect(user, '/settings'), isNull);
      expect(redirect(user, '/projects/5'), isNull);
    });

    test('po onboardingu strona onboardingu odsyła na Home', () {
      expect(redirect(user, '/onboarding'), '/');
    });
  });

  group('nowy użytkownik (bez onboardingu)', () {
    test('każda strona -> /onboarding', () {
      for (final path in ['/', '/projects/5', '/settings', '/login']) {
        expect(redirect(newUser, path), '/onboarding', reason: path);
      }
      expect(redirect(newUser, '/onboarding'), isNull);
    });

    test('gdy profil jeszcze się ładuje - bez przedwczesnego przekierowania', () {
      expect(redirect(userProfileLoading, '/projects'), isNull);
      expect(redirect(userProfileLoading, '/onboarding'), isNull);
    });
  });

  test('w trakcie sprawdzania sesji przy starcie - nic nie przekierowujemy', () {
    expect(redirect(starting, '/settings'), isNull);
  });
}
