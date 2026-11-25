import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'presentation/projects_page.dart';
import 'presentation/views/project_details_view.dart';

/// Trasy modułu Projects: lista `/projects` i szczegóły `/projects/:projectId`.
///
/// Szczegóły są trasą-dzieckiem listy, więc wejście z linku (np. odświeżenie przeglądarki
/// na `/projects/5`) buduje stos [lista, szczegóły] - "wstecz" zawsze wraca do listy.
abstract final class ProjectsRoutes {
  static const list = 'projects';
  static const listPath = '/projects';
  static const details = 'project-details';
  static const projectIdParam = 'projectId';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [
          GoRoute(
            path: listPath,
            name: list,
            builder: (context, state) => const ProjectsPage(),
            routes: [
              GoRoute(
                path: ':$projectIdParam',
                name: details,
                // Niepoprawne ID w adresie (np. /projects/abc) -> lista projektów
                redirect: (context, state) => _projectId(state) == null ? listPath : null,
                builder: (context, state) => ProjectDetailsView(projectId: _projectId(state)!),
              ),
            ],
          ),
        ],
      );

  static void openDetails(BuildContext context, int projectId) {
    context.goNamed(details, pathParameters: {projectIdParam: '$projectId'});
  }

  static int? _projectId(GoRouterState state) => int.tryParse(state.pathParameters[projectIdParam] ?? '');
}
