import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/widgets/app_frame.dart';

void main() {
  // ProviderScope przechowuje stan wszystkich providerów
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'English Learning App',
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Nawigacja: go_router (adresy URL, historia, przycisk "wstecz") - patrz core/routing/app_router.dart
      routerConfig: ref.watch(appRouterProvider),
      // Wszystkie strony (i dialogi) w "słupku" o szerokości telefonu na szerokich ekranach
      builder: (context, child) => AppFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
