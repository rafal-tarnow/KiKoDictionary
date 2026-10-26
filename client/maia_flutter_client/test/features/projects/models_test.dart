import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/projects/data/models/project.dart';
import 'package:maia_flutter_client/features/projects/data/models/project_task.dart';
import 'package:maia_flutter_client/features/projects/data/models/task_priority.dart';
import 'package:maia_flutter_client/features/projects/presentation/projects_ui.dart';

void main() {
  group('Project', () {
    test('fromJson parses API payload (int position, stats)', () {
      final project = Project.fromJson({
        'id': 1,
        'name': 'IELTS',
        'description': null,
        'color': '#673AB7',
        'position': 1000,
        'task_count': 4,
        'completed_task_count': 1,
        'created_at': '2026-10-26T09:37:30.499231Z',
        'updated_at': '2026-10-26T09:37:30.499231Z',
      });

      expect(project.position, 1000.0);
      expect(project.progress, 0.25);
      expect(project.createdAt.isUtc, isTrue);
    });

    test('draft sends null description to clear it', () {
      const draft = ProjectDraft(name: 'P', color: '#FF5722');

      expect(draft.toJson(), {'name': 'P', 'description': null, 'color': '#FF5722'});
    });
  });

  group('ProjectTask', () {
    Map<String, dynamic> json({String? dueDate, bool done = false}) => {
          'id': 7,
          'project_id': 1,
          'title': 'Write essay',
          'description': 'Topic: travel',
          'priority': 'high',
          'due_date': dueDate,
          'is_completed': done,
          'completed_at': null,
          'position': 1500.5,
          'created_at': '2026-10-26T09:37:30Z',
          'updated_at': '2026-10-26T09:37:30Z',
        };

    test('fromJson parses priority and date-only due date', () {
      final task = ProjectTask.fromJson(json(dueDate: '2026-12-24'));

      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, DateTime(2026, 12, 24));
      expect(task.position, 1500.5);
    });

    test('unknown priority falls back to none', () {
      expect(TaskPriority.fromApi('urgent'), TaskPriority.none);
    });

    test('isOverdue only for unfinished tasks with past due date', () {
      final now = DateTime(2026, 10, 26, 15);

      expect(ProjectTask.fromJson(json(dueDate: '2026-10-25')).isOverdue(now), isTrue);
      expect(ProjectTask.fromJson(json(dueDate: '2026-10-26')).isOverdue(now), isFalse);
      expect(ProjectTask.fromJson(json(dueDate: '2026-10-25', done: true)).isOverdue(now), isFalse);
      expect(ProjectTask.fromJson(json()).isOverdue(now), isFalse);
    });

    test('draft serialises due date as YYYY-MM-DD', () {
      final draft = TaskDraft(title: 'T', priority: TaskPriority.low, dueDate: DateTime(2027, 3, 5));

      expect(draft.toJson(), {
        'title': 'T',
        'description': null,
        'priority': 'low',
        'due_date': '2027-03-05',
      });
    });
  });

  group('ProjectsUi.formatDueDate', () {
    final now = DateTime(2026, 10, 26);

    test('relative labels', () {
      expect(ProjectsUi.formatDueDate(DateTime(2026, 10, 26), now: now), 'Today');
      expect(ProjectsUi.formatDueDate(DateTime(2026, 10, 27), now: now), 'Tomorrow');
      expect(ProjectsUi.formatDueDate(DateTime(2026, 10, 25), now: now), 'Yesterday');
    });

    test('absolute labels include year only when different', () {
      expect(ProjectsUi.formatDueDate(DateTime(2026, 12, 24), now: now), 'Dec 24');
      expect(ProjectsUi.formatDueDate(DateTime(2027, 1, 2), now: now), 'Jan 2, 2027');
    });
  });
}
