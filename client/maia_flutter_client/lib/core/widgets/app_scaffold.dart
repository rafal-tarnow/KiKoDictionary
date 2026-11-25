import 'package:flutter/material.dart';
import '../../features/auth/presentation/widgets/user_avatar_button.dart';
import 'main_drawer.dart';

/// Wspólny szkielet strony: AppBar w stylu aplikacji + Drawer + przycisk konta.
///
/// Każda strona buduje SWÓJ AppScaffold i sama decyduje o tytule, przyciskach w AppBarze
/// (np. filtr, sortowanie, odśwież), FAB-ie i dolnym pasku - wszystko w jednym pliku
/// ze stanem strony, bez centralnego "switcha" AppBarów.
class AppScaffold extends StatelessWidget {
  final String title;

  /// Zamiast [title], gdy tytuł ma być czymś więcej niż tekstem (np. ikona + nazwa projektu).
  final Widget? titleWidget;

  /// Przyciski strony w AppBarze; przycisk konta jest dokładany na końcu (patrz [showUserMenu]).
  final List<Widget> actions;

  /// Np. strzałka powrotu na podstronie. Domyślnie: przycisk Drawera.
  final Widget? leading;
  final double? titleSpacing;
  final Color? appBarBackgroundColor;
  final bool showUserMenu;
  final bool showDrawer;

  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color backgroundColor;

  const AppScaffold({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions = const [],
    this.leading,
    this.titleSpacing,
    this.appBarBackgroundColor,
    this.showUserMenu = true,
    this.showDrawer = true,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: leading,
        title: titleWidget ?? Text(title),
        titleSpacing: titleSpacing,
        elevation: 2,
        backgroundColor: appBarBackgroundColor,
        actions: [
          ...actions,
          if (showUserMenu) const UserAvatarButton(),
        ],
      ),
      drawer: showDrawer ? const MainDrawer() : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
