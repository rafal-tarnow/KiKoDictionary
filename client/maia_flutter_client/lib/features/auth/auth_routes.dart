import 'package:go_router/go_router.dart';
import 'presentation/forgot_password_page.dart';
import 'presentation/login_page.dart';
import 'presentation/onboarding_page.dart';
import 'presentation/register_page.dart';

/// Trasy modułu Auth. Leżą POZA gałęziami Drawera: nie trzeba pamiętać ich stanu,
/// a onboarding jest pełnoekranowy (bez Drawera i AppBara).
abstract final class AuthRoutes {
  static const login = 'login';
  static const loginPath = '/login';
  static const register = 'register';
  static const registerPath = '/register';
  static const forgotPassword = 'forgot-password';
  static const forgotPasswordPath = '/forgot-password';
  static const onboarding = 'onboarding';
  static const onboardingPath = '/onboarding';

  /// Strony tylko dla gości - zalogowany użytkownik jest z nich przekierowywany.
  static const guestOnlyPaths = {loginPath, registerPath, forgotPasswordPath};

  static List<RouteBase> routes() => [
        GoRoute(path: loginPath, name: login, builder: (context, state) => const LoginPage()),
        GoRoute(path: registerPath, name: register, builder: (context, state) => const RegisterPage()),
        GoRoute(path: forgotPasswordPath, name: forgotPassword, builder: (context, state) => const ForgotPasswordPage()),
        GoRoute(path: onboardingPath, name: onboarding, builder: (context, state) => const OnboardingPage()),
      ];
}
