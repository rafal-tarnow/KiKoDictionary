import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maia_flutter_client/features/auth/presentation/register_page.dart';
import 'core/navigation_provider.dart';
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
import 'features/health/services_health_page.dart';
import 'features/captcha/captcha_page.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const List<Widget> _pages = [
    HomePage(),
    DictionaryPage(),
    WordsPage(),
    SentencesPage(),
    RegisterPage(),
    TestPage(),
    ServicesHealthPage(),
    CaptchaPage(),
  ];

  static final List<PreferredSizeWidget> _appBars = [
    const HomeAppBar(),
    AppBar(title: const Text("Dictionary"), elevation: 2,),
    AppBar(title: const Text("Words"), elevation: 2,),
    const SentencesAppBar(),
    AppBar(title: const Text("Register page"), elevation: 2,),
    const TestAppBar(),
    AppBar(title: const Text("Health Check"), elevation: 2,),
    AppBar(title: const Text("Captcha Demo"), elevation: 2,),
  ];

  // static const List<String> _titles = [
  //   'Ogłoszenia parafialne',
  //   'Dictionary',
  //   'Words',
  //   'Sentences',
  //   'Test',
  //   'Health Check',
  // ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRect(
              //ClipRect jest potrzebny bo inaczej boczny Drawer rysuje sie poza oknem aplikacji w widoku np na tablecie, dlatego trzeba przyciac Drawer do glownego słupka aplikacji
              child: Scaffold(
                //backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundColor: const Color(0xFFFFFFFF),
                appBar: _appBars[selectedIndex],
                // appBar: AppBar(
                //   title: Text(_titles[selectedIndex]),
                //   elevation: 2,
                // ),
                drawer: const MainDrawer(),
                body: _pages[selectedIndex],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
