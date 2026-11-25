import 'package:go_router/go_router.dart';
import 'captcha_page.dart';

/// Strona deweloperska (poza Drawerem): /dev/captcha
abstract final class CaptchaRoutes {
  static const captcha = 'dev-captcha';
  static const captchaPath = '/dev/captcha';

  static StatefulShellBranch branch() => StatefulShellBranch(
        routes: [GoRoute(path: captchaPath, name: captcha, builder: (context, state) => const CaptchaPage())],
      );
}
