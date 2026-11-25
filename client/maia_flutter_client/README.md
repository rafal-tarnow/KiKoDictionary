# maia_flutter_client

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run release version on android
w prawym dolnym rogu VSC wybrac platforme docelowa a nastepnie:
flutter run --release

## Run relase version on windows
flutter run -d windows --release

## Build web version

Zalecane (WebAssembly z automatycznym zapasowym JavaScriptem dla starszych przeglądarek):

flutter build web --wasm --base-href "/english_learner/flutter/"

Wersja tylko JavaScript (gdyby z Wasm był problem):

flutter build web --base-href "/english_learner/flutter/"



Uwagi:
- Optymalizacja jest domyślnie maksymalna (`--release`, `-O4`) - nie trzeba dodawać flag.
- Hosting: GitHub Pages (https://rafal-tarnow.github.io/english_learner/flutter/) sam kompresuje pliki (gzip).
  Wasm działa tam w trybie jednowątkowym (GitHub Pages nie pozwala ustawić nagłówków COOP/COEP) - to OK.
- Ekran ładowania (logo + kółko) jest w `web/index.html` i znika przy pierwszej klatce aplikacji
  (zdarzenie `flutter-first-frame`).


## Komendy ktore trzeba wywolac po swiezym pobranu repozytorium (windows)
1. flutter clean
2. flutter pub get
3. flutter doctor
4. flutter run -d windows

## Nawigacja (go_router)

Każda strona ma adres URL (w wersji web: `.../flutter/#/projects/5`), historię i działający przycisk "wstecz".

- `lib/core/routing/app_router.dart` - składa trasy wszystkich modułów + strażnik (redirect):
  gość na stronie wymagającej logowania -> `/login?from=...`, nowy użytkownik -> `/onboarding`.
- `lib/core/routing/route_access.dart` - reguły strażnika (czysta funkcja, testy w `test/core/routing/`).
- `lib/features/<moduł>/<moduł>_routes.dart` - trasy danego modułu (ścieżki, nazwy, strony).
- `lib/core/widgets/app_scaffold.dart` - wspólny szkielet strony (AppBar + Drawer + przycisk konta);
  każda strona sama podaje tytuł i swoje przyciski w AppBarze.
- Sekcje z Drawera to gałęzie `StatefulShellRoute`: pamiętają swój stan i budują się przy pierwszym wejściu.

Nawigacja w kodzie: `context.goNamed(ProjectsRoutes.list)`, `ProjectsRoutes.openDetails(context, id)`, `context.pop()`.

### Jak dodać nową stronę
1. Strona zwraca `AppScaffold(title: ..., actions: [...], body: ...)`.
2. W module dodaj `<moduł>_routes.dart` z nazwą, ścieżką i `StatefulShellBranch` (sekcja Drawera)
   albo zwykłym `GoRoute` (strona poza Drawerem, jak logowanie).
3. Dopisz gałąź w `app_router.dart` (i ewentualnie pozycję w `core/widgets/main_drawer.dart`).
4. Jeśli strona wymaga logowania - dopisz jej ścieżkę do `routeAccessRules.loginRequiredPaths`.
