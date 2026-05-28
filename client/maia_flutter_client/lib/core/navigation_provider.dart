import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/app_page.dart'; // ================= [ZMIANA]: Import Enuma =================

// ================= [ZMIANA]: Zmiana typu z int na AppPage =================
final navigationProvider = StateProvider<AppPage>((ref) => AppPage.home);
// UWAGA: Zmieniłem nazwę z navigationIndexProvider na navigationProvider,
// ponieważ przechowujemy teraz "Stronę", a nie "Indeks".