import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/projects/data/projects_repository.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/projects_session_provider.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/selected_project_provider.dart';
import 'package:maia_flutter_client/features/projects/presentation/views/project_list_view.dart';
import 'fakes.dart';

void main() {
  Future<ProviderContainer> pumpListView(WidgetTester tester, FakeProjectsRepository repo) async {
    final container = ProviderContainer(overrides: [
      projectsRepositoryProvider.overrideWithValue(repo),
      projectsSessionProvider.overrideWithValue(true),
    ]);
    addTearDown(container.dispose);

    // Szerokość telefonu - wyłapuje ewentualne overflow layoutu
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProjectListView()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
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

  testWidgets('shows empty state when there are no projects', (tester) async {
    await pumpListView(tester, FakeProjectsRepository([]));

    expect(find.text("You don't have any projects yet."), findsOneWidget);
  });

  testWidgets('tapping a project opens it', (tester) async {
    final container = await pumpListView(tester, FakeProjectsRepository([buildProject(5, name: 'Open me')]));

    await tester.tap(find.text('Open me'));
    await tester.pump();

    expect(container.read(selectedProjectIdProvider), 5);
  });
}
