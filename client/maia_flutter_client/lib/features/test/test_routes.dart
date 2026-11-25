import 'package:go_router/go_router.dart';
import 'test_page.dart';

/// Strona deweloperska (poza Drawerem): /dev/test
abstract final class TestRoutes {
  static const test = 'dev-test';
  static const testPath = '/dev/test';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: testPath, name: test, builder: (context, state) => const TestPage())],
      );
}
