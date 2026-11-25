import 'package:go_router/go_router.dart';
import 'home_page.dart';

/// Trasy modułu Home.
abstract final class HomeRoutes {
  static const home = 'home';
  static const homePath = '/';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: homePath, name: home, builder: (context, state) => const HomePage())],
      );
}
