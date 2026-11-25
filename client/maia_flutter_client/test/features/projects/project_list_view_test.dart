import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maia_flutter_client/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maia_flutter_client/features/projects/data/projects_repository.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/projects_session_provider.dart';
import 'package:maia_flutter_client/features/projects/presentation/views/project_list_view.dart';
import 'package:maia_flutter_client/features/user/presentation/controllers/user_controller.dart';
import '../../core/routing/routing_fakes.dart';
import 'fakes.dart';

void main() {
  /// Lista projektów pod prawdziwym routerem (`/projects` -> `/projects/:projectId`).
  Future<GoRouter> pumpListView(WidgetTester tester, FakeProjectsRepository repo) async {
    final container = ProviderContainer(overrides: [
      projectsRepositoryProvider.overrideWithValue(repo),
      projectsSessionProvider.overrideWithValue(true),
      authControllerProvider.overrideWith((ref) => FakeAuthController(loggedIn: true)),
      userControllerProvider.overrideWith((ref) => FakeUserController(testUser())),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/projects',
      routes: [
        GoRoute(
          path: '/projects',
          name: 'projects',
          builder: (context, state) => const ProjectListView(),
          routes: [
            GoRoute(
              path: ':projectId',
              name: 'project-details',
              builder: (context, state) => Text('details ${state.pathParameters['projectId']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    // Szerokość telefonu - wyłapuje ewentualne overflow layoutu
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shows projects with progress', (tester) async {
    await pumpListView(
      tester,
      FakeProjectsRepository([
        buildProject(1, name: 'IELTS', tasks: 4, completed: 1),
        buildProject(2, name: 'Vocabulary'),
      ]),
    );

    expect(find.text('IELTS'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('NEW PROJECT'), findsOneWidget);
  });

  testWidgets('has its own app bar with title and refresh button', (tester) async {
    await pumpListView(tester, FakeProjectsRepository([buildProject(1)]));

    expect(find.widgetWithText(AppBar, 'Projects'), findsOneWidget);
    expect(find.byTooltip('Refresh'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no projects', (tester) async {
    await pumpListView(tester, FakeProjectsRepository([]));

    expect(find.text("You don't have any projects yet."), findsOneWidget);
  });

  testWidgets('tapping a project opens /projects/:projectId', (tester) async {
    final router = await pumpListView(tester, FakeProjectsRepository([buildProject(5, name: 'Open me')]));

    await tester.tap(find.text('Open me'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/projects/5');
    expect(find.text('details 5'), findsOneWidget);
  });
}
