import 'package:flutter/material.dart';
import 'package:maia_flutter_client/features/auth/presentation/widgets/user_avatar_button.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Ogłoszenia parafialne"),
      elevation: 2,
      // Nie musisz dodawać leading/hamburgera - Flutter doda go sam!
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
        const UserAvatarButton(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}