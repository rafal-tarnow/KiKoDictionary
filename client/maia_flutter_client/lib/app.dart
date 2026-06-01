import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/features/auth/presentation/forgot_password_page.dart';
import 'package:maia_flutter_client/features/auth/presentation/login_page.dart';
import 'package:maia_flutter_client/features/auth/presentation/register_page.dart';
import 'package:maia_flutter_client/features/auth/presentation/widgets/user_avatar_button.dart';
import 'core/navigation_provider.dart';
import 'core/routing/app_page.dart';
import 'core/widgets/main_drawer.dart';
import 'features/home/home_page.dart';
import 'features/home/home_app_bar.dart';
import 'features/dictionary/dictionary_page.dart';
import 'features/words/words_page.dart';
import 'features/sentences/sentences_page.dart';
import 'features/sentences/sentences_app_bar.dart';
import 'features/test/test_page.dart';
import 'features/test/test_app_bar.dart';
import 'core/app_sizes.dart'; // Import stałych
//import 'features/health/services_health_page.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/captcha/captcha_page.dart';
import 'features/auth/presentation/onboarding_page.dart';
import 'package:maia_flutter_client/features/sentences/community_sentences_page.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  Widget _buildPage(AppPage page) {
    switch (page) {
      case AppPage.home: return const HomePage();
      case AppPage.dictionary: return const DictionaryPage();
      case AppPage.words: return const WordsPage();
      case AppPage.sentences: return const SentencesPage();
      case AppPage.register: return const RegisterPage();
      case AppPage.login: return const LoginPage();
      case AppPage.test: return const TestPage();
      //case AppPage.health: return const ServicesHealthPage();
      case AppPage.captcha: return const CaptchaPage();
      case AppPage.forgotPassword: return const ForgotPasswordPage();
      case AppPage.settings: return const SettingsPage();
      case AppPage.onboarding: return const OnboardingPage();
      case AppPage.communitySentences: return const CommunitySentencesPage();
    }
  }

  PreferredSizeWidget? _buildAppBar(AppPage page) {
    switch (page) {
      case AppPage.home: return const HomeAppBar();
      case AppPage.sentences: return const SentencesAppBar();
      case AppPage.test: return const TestAppBar();
      case AppPage.onboarding: return null; // Brak AppBar dla Onboardingu
      
      // Standardowe AppBary
      case AppPage.dictionary: return _standardAppBar("Dictionary");
      case AppPage.words: return _standardAppBar("Words");
      case AppPage.register: return _standardAppBar("Register");
      case AppPage.login: return _standardAppBar("Log in");
      //case AppPage.health: return _standardAppBar("Health Check");
      case AppPage.captcha: return _standardAppBar("Captcha Demo");
      case AppPage.forgotPassword: return _standardAppBar("Reset Password");
      case AppPage.settings: return _standardAppBar("Settings");
      case AppPage.communitySentences: return _standardAppBar("Community");
    }
  }

  // Funkcja pomocnicza, żeby nie duplikować kodu standardowego AppBara (DRY)
  PreferredSizeWidget _standardAppBar(String title) {
    return AppBar(
      title: Text(title),
      elevation: 2,
      actions: const [UserAvatarButton()],
    );
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPage = ref.watch(navigationProvider);

    // Sprawdzamy czy to index onboardingu
    final isFullScreenBinding = selectedPage.isFullScreen;

    return Container(
      //szare tło aplikacji
      // Zamieniamy surfaceVariant na surfaceContainerHighest
      color: const Color(0xFFE0E0E0),
      // color: Theme.of(
      //   context,
      // ).colorScheme.surfaceContainer,
      //color: const Color(0xFFE0E0E0),
      // color: Theme.of(
      //   context,
      // ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxMobileWidth),
          child: Container(
            // Ten kontener dodaje cień i ogranicza Scaffold
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRect(
              // ClipRect jest potrzebny bo inaczej boczny Drawer rysuje sie poza oknem 
              // aplikacji w widoku np na tablecie, dlatego trzeba przyciac Drawer do glownego słupka aplikacji
              child: Scaffold(
                backgroundColor: const Color(0xFFFFFFFF),
                appBar: isFullScreenBinding ? null : _buildAppBar(selectedPage),
                drawer: isFullScreenBinding ? null : const MainDrawer(),
                body: IndexedStack(
                  index: selectedPage.index, 
                  children: AppPage.values.map((p) => _buildPage(p)).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
