import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/projects/data/models/project.dart';
import 'package:maia_flutter_client/features/projects/data/project_tasks_repository.dart';
import 'package:maia_flutter_client/features/projects/data/projects_repository.dart';
import 'package:maia_flutter_client/features/projects/domain/action_result.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/project_tasks_controller.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/projects_controller.dart';
import 'package:maia_flutter_client/features/projects/presentation/controllers/projects_session_provider.dart';
import 'fakes.dart';

/// Oddaje sterowanie pętli zdarzeń, żeby zakończyły się microtaski (ładowanie w build()).
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeProjectsRepository projectsRepo;
  late FakeProjectTasksRepository tasksRepo;
  late StateController<bool> session;
  late ProviderContainer container;

  setUp(() {
    projectsRepo = FakeProjectsRepository([
      buildProject(1, tasks: 2, completed: 0),
      buildProject(2),
      buildProject(3),
    ]);
    tasksRepo = FakeProjectTasksRepository([buildTask(10), buildTask(11)]);

    final sessionState = StateProvider<bool>((ref) => true);
    container = ProviderContainer(overrides: [
      projectsRepositoryProvider.overrideWithValue(projectsRepo),
      projectTasksRepositoryProvider.overrideWithValue(tasksRepo),
      projectsSessionProvider.overrideWith((ref) => ref.watch(sessionState)),
    ]);
    session = container.read(sessionState.notifier);
    addTearDown(container.dispose);
  });

  List<int> projectIds() => container.read(projectsControllerProvider).projects.map((p) => p.id).toList();

  group('ProjectsController', () {
    setUp(() async {
      container.listen(projectsControllerProvider, (_, _) {});
      await settle();
    });

    test('loads projects automatically when logged in', () {
      final state = container.read(projectsControllerProvider);

      expect(state.isLoading, isFalse);
      expect(projectIds(), [1, 2, 3]);
    });

    test('clears data on logout and reloads on login', () async {
      session.state = false;
      await settle();
      expect(projectIds(), isEmpty);

      session.state = true;
      await settle();
      expect(projectIds(), [1, 2, 3]);
    });

    test('load error is exposed for the retry banner', () async {
      projectsRepo.shouldFail = true;

      await container.read(projectsControllerProvider.notifier).loadProjects();

      expect(container.read(projectsControllerProvider).errorMessage, 'Boom');
    });

    test('create appends project to the end', () async {
      final result = await container
          .read(projectsControllerProvider.notifier)
          .createProject(const ProjectDraft(name: 'New', color: '#673AB7'));

      expect(result, isA<ActionSuccess>());
      expect(container.read(projectsControllerProvider).projects.last.name, 'New');
    });

    test('reorder sends neighbours of the new position', () async {
      final result = await container.read(projectsControllerProvider.notifier).reorderProjects(2, 0);

      expect(result.isSuccess, isTrue);
      expect(projectIds(), [3, 1, 2]);
      expect(projectsRepo.reorderCalls.single, (id: 3, previousId: null, nextId: 1));
    });

    test('failed reorder rolls back and reports the error', () async {
      projectsRepo.shouldFail = true;

      final result = await container.read(projectsControllerProvider.notifier).reorderProjects(0, 2);

      expect(result, isA<ActionFailure>());
      expect(projectIds(), [1, 2, 3]);
    });

    test('failed delete restores the project', () async {
      projectsRepo.shouldFail = true;

      final result = await container.read(projectsControllerProvider.notifier).deleteProject(2);

      expect((result as ActionFailure).message, 'Boom');
      expect(projectIds(), [1, 2, 3]);
    });
  });

  group('ProjectTasksController', () {
    setUp(() async {
      container.listen(projectsControllerProvider, (_, _) {});
      container.listen(projectTasksControllerProvider(1), (_, _) {});
      await settle();
    });

    ProjectTasksController tasksController() => container.read(projectTasksControllerProvider(1).notifier);

    test('loads tasks of the project', () {
      final ids = container.read(projectTasksControllerProvider(1)).tasks.map((t) => t.id);

      expect(ids, [10, 11]);
    });

    test('toggling a task updates project statistics', () async {
      final task = container.read(projectTasksControllerProvider(1)).tasks.first;

      await tasksController().toggleCompleted(task);

      final project = container.read(projectsControllerProvider).findById(1)!;
      expect(project.taskCount, 2);
      expect(project.completedTaskCount, 1);
    });

    test('failed toggle rolls back the checkbox', () async {
      tasksRepo.shouldFail = true;
      final task = container.read(projectTasksControllerProvider(1)).tasks.first;

      final result = await tasksController().toggleCompleted(task);

      expect(result, isA<ActionFailure>());
      expect(container.read(projectTasksControllerProvider(1)).tasks.first.isCompleted, isFalse);
    });

    test('deleting a task decreases the project task count', () async {
      await tasksController().deleteTask(10);

      expect(container.read(projectsControllerProvider).findById(1)!.taskCount, 1);
    });
  });
}
