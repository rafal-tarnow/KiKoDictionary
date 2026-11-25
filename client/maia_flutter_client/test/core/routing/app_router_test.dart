import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maia_flutter_client/core/routing/app_router.dart';
import 'package:maia_flutter_client/features/auth/data/models/user_model.dart';
import 'package:maia_flutter_client/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maia_flutter_client/features/auth/presentation/login_page.dart';
import 'package:maia_flutter_client/features/auth/presentation/onboarding_page.dart';
import 'package:maia_flutter_client/features/projects/data/project_tasks_repository.dart';
import 'package:maia_flutter_client/features/projects/data/projects_repository.dart';
import 'package:maia_flutter_client/features/projects/presentation/projects_page.dart';
import 'package:maia_flutter_client/features/user/presentation/controllers/user_controller.dart';
import 'package:maia_flutter_client/main.dart';
import '../../features/projects/fakes.dart';
import 'routing_fakes.dart';

/// Testy całej aplikacji z PRAWDZIWYM routerem (MyApp + appRouterProvider);
/// podmienione są tylko sesja, profil i repozytoria (bez sieci).
void main() {
  late FakeAuthController auth;
  late FakeUserController users;
  late GoRouter router;

  String location() => router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(WidgetTester tester, {bool loggedIn = false, User? user}) async {
    tester.view.physicalSize = const Size(400 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    auth = FakeAuthController(loggedIn: loggedIn);
    users = FakeUserController(user);
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
      userControllerProvider.overrideWith((ref) => users),
      projectsRepositoryProvider.overrideWithValue(
        FakeProjectsRepository([buildProject(5, name: 'IELTS'), buildProject(6, name: 'Vocabulary')]),
      ),
      projectTasksRepositoryProvider.overrideWithValue(FakeProjectTasksRepository([buildTask(1, projectId: 5)])),
    ]);
    addTearDown(container.dispose);
    router = container.read(appRouterProvider);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    await tester.pumpAndSettle();
  }

  Future<void> goTo(WidgetTester tester, String path) async {
    router.go(path);
    await tester.pumpAndSettle();
  }

  testWidgets('start na Home; pozostałe sekcje budują się dopiero przy pierwszym wejściu', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());

    expect(location(), '/');
    expect(find.text('Home Page - Learning English'), findsOneWidget);
    expect(find.byType(ProjectsPage, skipOffstage: false), findsNothing);
  });

  testWidgets('Drawer przenosi do sekcji i zaznacza aktywną pozycję', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();

    expect(location(), '/projects');
    expect(find.text('IELTS'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final projectsTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Projects').last, matching: find.byType(ListTile)),
    );
    expect(projectsTile.selected, isTrue);
  });

  testWidgets('kliknięcie projektu otwiera /projects/:id, a "wstecz" wraca do listy', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());
    await goTo(tester, '/projects');

    await tester.tap(find.text('IELTS'));
    await tester.pumpAndSettle();
    expect(location(), '/projects/5');
    expect(find.text('Task 1'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(location(), '/projects');
    expect(find.text('Vocabulary'), findsOneWidget);
  });

  testWidgets('link prosto do projektu (np. odświeżenie strony) - "wstecz" i tak wraca do listy', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());

    await goTo(tester, '/projects/5');
    expect(find.text('Task 1'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(location(), '/projects');
  });

  testWidgets('gość otwiera link do projektu -> logowanie -> po zalogowaniu wraca do projektu', (tester) async {
    await pumpApp(tester);

    await goTo(tester, '/projects/5');
    expect(location(), '/login?from=%2Fprojects%2F5');
    expect(find.byType(LoginPage), findsOneWidget);

    auth.setLoggedIn(true);
    users.setUser(testUser());
    await tester.pumpAndSettle();

    expect(location(), '/projects/5');
    expect(find.text('Task 1'), findsOneWidget);
  });

  testWidgets('nowy użytkownik trafia na onboarding, a po jego ukończeniu na Home', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser(onboardingCompleted: false));

    expect(location(), '/onboarding');
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing); // pełny ekran, bez Drawera

    users.setUser(testUser());
    await tester.pumpAndSettle();
    expect(location(), '/');
  });

  testWidgets('wylogowanie na stronie wymagającej logowania przenosi do logowania', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());
    await goTo(tester, '/projects/5');

    auth.setLoggedIn(false);
    users.setUser(null);
    await tester.pumpAndSettle();

    expect(location(), startsWith('/login'));
  });

  testWidgets('nieznany adres pokazuje stronę "nie znaleziono" z powrotem na Home', (tester) async {
    await pumpApp(tester);

    await goTo(tester, '/no-such-page');
    expect(find.text("This page doesn't exist."), findsOneWidget);

    await tester.tap(find.text('GO TO HOME'));
    await tester.pumpAndSettle();
    expect(location(), '/');
  });

  testWidgets('niepoprawne ID projektu w adresie -> lista projektów', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());

    await goTo(tester, '/projects/abc');

    expect(location(), '/projects');
  });

  testWidgets('nieistniejący projekt -> komunikat i powrót do listy', (tester) async {
    await pumpApp(tester, loggedIn: true, user: testUser());

    await goTo(tester, '/projects/999');
    expect(find.text('Project not found.'), findsOneWidget);

    await tester.tap(find.text('BACK TO PROJECTS'));
    await tester.pumpAndSettle();
    expect(location(), '/projects');
  });
}
