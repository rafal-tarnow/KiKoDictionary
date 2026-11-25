import 'package:go_router/go_router.dart';
import 'presentation/settings_page.dart';

/// Trasy modułu Settings (wymaga zalogowania - patrz app_router.dart).
abstract final class SettingsRoutes {
  static const settings = 'settings';
  static const settingsPath = '/settings';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: settingsPath, name: settings, builder: (context, state) => const SettingsPage())],
      );
}
