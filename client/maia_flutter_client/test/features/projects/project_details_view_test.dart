import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/projects/data/models/project_task.dart';
import 'package:maia_flutter_client/features/projects/data/models/task_priority.dart';
import 'package:maia_flutter_client/features/projects/data/project_tasks_repository.dart';
import 'package:maia_flutter_client/features/projects/data/projects_repository.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/projects_session_provider.dart';
import 'package:maia_flutter_client/features/projects/presentation/views/project_details_view.dart';
import 'fakes.dart';

void main() {
  final detailedTask = ProjectTask(
    id: 1,
    projectId: 1,
    title: 'Write an essay about travelling',
    description: 'At least 250 words, use the past perfect tense.',
    priority: TaskPriority.high,
    dueDate: DateTime(2020, 1, 1), // po terminie
    isCompleted: false,
    completedAt: null,
    position: 1000,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<void> pumpDetails(WidgetTester tester, List<ProjectTask> tasks) async {
    final container = ProviderContainer(overrides: [
      projectsRepositoryProvider.overrideWithValue(FakeProjectsRepository([buildProject(1, name: 'IELTS')])),
      projectTasksRepositoryProvider.overrideWithValue(FakeProjectTasksRepository(tasks)),
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
        child: const MaterialApp(home: ProjectDetailsView(projectId: 1)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows tasks with priority, overdue date and progress header', (tester) async {
    await pumpDetails(tester, [detailedTask, buildTask(2, isCompleted: true)]);

    expect(find.text('Write an essay about travelling'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy), findsOneWidget); // termin minął
    expect(find.text('1 of 2 done · 50%'), findsOneWidget);
  });

  testWidgets('shows empty state for a project without tasks', (tester) async {
    await pumpDetails(tester, []);

    expect(find.text('This project has no tasks yet.'), findsOneWidget);
  });

  testWidgets('ADD TASK opens the task form', (tester) async {
    await pumpDetails(tester, []);

    await tester.tap(find.text('ADD TASK'));
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsOneWidget);
    expect(find.text('Set due date'), findsOneWidget);
    for (final priority in TaskPriority.values) {
      expect(find.text(priority.label), findsOneWidget);
    }
  });

  testWidgets('task form validates the title', (tester) async {
    await pumpDetails(tester, []);
    await tester.tap(find.text('ADD TASK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'ADD TASK'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a task title'), findsOneWidget);
  });
}
