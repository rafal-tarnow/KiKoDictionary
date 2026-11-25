import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maia_flutter_client/features/sentences/data/sentence_model.dart';
import 'package:maia_flutter_client/features/sentences/data/sentences_repository.dart';
import 'package:maia_flutter_client/features/sentences/presentation/sentences_provider.dart';
import 'package:maia_flutter_client/features/sentences/presentation/widgets/sentence_tile.dart';
import 'package:maia_flutter_client/features/sentences/sentences_page.dart';

Sentence _sentence(int id, {String source = 'pl', String target = 'en'}) => Sentence(
      id: id,
      originalText: 'Zdanie $id',
      translatedText: 'Sentence $id',
      sourceLanguage: source,
      targetLanguage: target,
      createdAt: '2026-11-24T10:00:00Z',
      position: id * 1000.0,
    );

DioException _serverError() {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 500, data: {'detail': 'Boom'}),
  );
}

class _FakeSentencesRepository extends SentencesRepository {
  List<Sentence> items;
  int totalPages;
  bool shouldFail = false;
  final List<int> loadedPages = [];
  final List<({int id, int? previousId, int? nextId})> reorderCalls = [];
  final List<String> moveCalls = [];

  _FakeSentencesRepository(this.items, {this.totalPages = 1}) : super(Dio());

  @override
  Future<SentencesResponse> getSentences({required int page, int perPage = 10}) async {
    loadedPages.add(page);
    return SentencesResponse(List.of(items), totalPages);
  }

  @override
  Future<Sentence> reorderSentence(int id, {int? previousId, int? nextId}) async {
    reorderCalls.add((id: id, previousId: previousId, nextId: nextId));
    if (shouldFail) throw _serverError();
    return items.firstWhere((s) => s.id == id);
  }

  @override
  Future<Sentence> moveSentenceToTop(int id) async {
    moveCalls.add('top:$id');
    if (shouldFail) throw _serverError();
    return items.firstWhere((s) => s.id == id);
  }

  @override
  Future<Sentence> moveSentenceToBottom(int id) async {
    moveCalls.add('bottom:$id');
    if (shouldFail) throw _serverError();
    return items.firstWhere((s) => s.id == id);
  }
}

/// Zalogowany użytkownik bez prawdziwego storage / sieci.
class _LoggedInAuthController extends StateNotifier<AuthState> implements AuthController {
  _LoggedInAuthController() : super(const AuthState(isAuthenticated: true, isAppLoading: false));

  @override
  Future<void> checkAuthStatus() async {}

  @override
  void setAuthenticated(bool isAuthenticated) {}

  @override
  Future<void> logout() async {}
}

void main() {
  group('SentencesNotifier - kolejność', () {
    late _FakeSentencesRepository repo;
    late SentencesNotifier notifier;

    setUp(() async {
      repo = _FakeSentencesRepository([_sentence(1), _sentence(2), _sentence(3)], totalPages: 3);
      notifier = SentencesNotifier(repo);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => notifier.dispose());

    test('przeciągnięcie wysyła sąsiadów nowej pozycji', () async {
      final ok = await notifier.reorder(0, 2);

      expect(ok, isTrue);
      expect(notifier.state.sentences.map((s) => s.id), [2, 3, 1]);
      expect(repo.reorderCalls.single, (id: 1, previousId: 3, nextId: null));
    });

    test('nieudane przeciągnięcie przywraca poprzednią kolejność', () async {
      repo.shouldFail = true;

      final ok = await notifier.reorder(2, 0);

      expect(ok, isFalse);
      expect(notifier.state.sentences.map((s) => s.id), [1, 2, 3]);
      expect(notifier.state.errorMessage, 'Boom');
    });

    test('"na początek" i "na koniec" wołają API i przeładowują bieżącą stronę', () async {
      repo.loadedPages.clear();

      expect(await notifier.moveToTop(3), isTrue);
      expect(await notifier.moveToBottom(1), isTrue);

      expect(repo.moveCalls, ['top:3', 'bottom:1']);
      expect(repo.loadedPages, [1, 1]);
    });

    test('pierwszy / ostatni element całej listy', () {
      final state = notifier.state; // strona 1 z 3

      expect(state.isFirstOverall(0), isTrue);
      expect(state.isFirstOverall(1), isFalse);
      expect(state.isLastOverall(2), isFalse); // to nie ostatnia strona
    });
  });

  group('SentenceTile', () {
    Future<void> pumpTile(WidgetTester tester, Sentence sentence, {bool isFirst = false}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [sentencesRepositoryProvider.overrideWithValue(_FakeSentencesRepository([sentence]))],
        child: MaterialApp(
          home: Scaffold(
            body: ReorderableListView(
              buildDefaultDragHandles: false,
              onReorderItem: (_, _) {},
              children: [
                SentenceTile(key: const ValueKey(1), sentence: sentence, index: 0, isFirstOverall: isFirst),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    bool isBlurred(WidgetTester tester, String text) =>
        find.ancestor(of: find.text(text), matching: find.byType(ImageFiltered)).evaluate().isNotEmpty;

    testWidgets('tekst po angielsku jest domyślnie rozmyty, oko go odkrywa i chowa', (tester) async {
      await pumpTile(tester, _sentence(1));

      expect(isBlurred(tester, 'Sentence 1'), isTrue);
      expect(isBlurred(tester, 'Zdanie 1'), isFalse);

      await tester.tap(find.byTooltip('Show English'));
      await tester.pumpAndSettle();
      expect(isBlurred(tester, 'Sentence 1'), isFalse);

      await tester.tap(find.byTooltip('Hide English'));
      await tester.pumpAndSettle();
      expect(isBlurred(tester, 'Sentence 1'), isTrue);
    });

    testWidgets('na wąskim telefonie (360 px) tekst dostaje większość szerokości kafelka', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 740 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final longSentence = Sentence(
        id: 1,
        originalText: 'To jest bardzo długie zdanie, które na pewno zawinie się do kilku linii na telefonie, '
            'bo ma dużo słów i sporo znaków',
        translatedText: 'Sentence 1',
        sourceLanguage: 'pl',
        targetLanguage: 'en',
        createdAt: '2026-11-24T10:00:00Z',
      );

      await pumpTile(tester, longSentence);

      // Zawinięty tekst wypełnia całą szerokość przeznaczoną na treść
      final textWidth = tester.getSize(find.textContaining('bardzo długie')).width;
      expect(textWidth, greaterThanOrEqualTo(280)); // poprzedni układ dawał ok. 208 px

      // Uchwyt i oko na środku wysokości kafelka, menu w prawym górnym rogu, nad okiem
      final card = tester.getRect(find.byType(Card));
      final handle = tester.getCenter(find.byIcon(Icons.drag_indicator));
      final menu = tester.getRect(find.byTooltip('More actions'));
      final eye = tester.getCenter(find.byTooltip('Show English'));
      expect(handle.dy, closeTo(card.center.dy, 1));
      expect(eye.dy, closeTo(card.center.dy, 1));
      expect(menu.top, closeTo(card.top + 8, 1)); // tuż przy górnej krawędzi (margines 4 + padding 4)
      expect(menu.center.dx, closeTo(eye.dx, 1));
      // Tekst nie wchodzi pod kolumnę akcji (może się z nią stykać)
      expect(menu.left, greaterThanOrEqualTo(tester.getTopRight(find.textContaining('bardzo długie')).dx));
    });

    testWidgets('przy niskim kafelku oko nie zachodzi na menu', (tester) async {
      await pumpTile(tester, _sentence(1)); // krótkie zdanie = niski kafelek

      final menu = tester.getRect(find.byTooltip('More actions'));
      final eye = tester.getRect(find.byTooltip('Show English'));
      final card = tester.getRect(find.byType(Card));
      expect(eye.top, greaterThanOrEqualTo(menu.bottom - 0.5));
      expect(eye.bottom, lessThanOrEqualTo(card.bottom));
      expect(tester.getCenter(find.byIcon(Icons.drag_indicator)).dy, closeTo(card.center.dy, 1));
    });

    testWidgets('dotknięcie rozmytego tekstu też go odkrywa', (tester) async {
      await pumpTile(tester, _sentence(1));

      await tester.tap(find.text('Sentence 1'));
      await tester.pumpAndSettle();

      expect(isBlurred(tester, 'Sentence 1'), isFalse);
    });

    testWidgets('gdy angielski jest językiem źródłowym, rozmyty jest oryginał', (tester) async {
      await pumpTile(tester, _sentence(1, source: 'en', target: 'pl'));

      expect(isBlurred(tester, 'Zdanie 1'), isTrue);
      expect(isBlurred(tester, 'Sentence 1'), isFalse);
    });

    testWidgets('edycja i usuwanie są w menu, "Move to top" wyłączone dla pierwszego zdania', (tester) async {
      await pumpTile(tester, _sentence(1), isFirst: true);

      // Brak osobnych przycisków edycji / usuwania na kafelku
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();

      for (final label in ['Edit', 'Move to top', 'Move to end', 'Delete']) {
        expect(find.text(label), findsOneWidget);
      }
      final moveToTop = tester.widget<PopupMenuItem<Object?>>(
        find.ancestor(of: find.text('Move to top'), matching: find.byWidgetPredicate((w) => w is PopupMenuItem)),
      );
      expect(moveToTop.enabled, isFalse);
    });
  });

  group('SentencesPage - komunikat po "Move to end"', () {
    Future<_FakeSentencesRepository> pumpPageWithPages(WidgetTester tester) async {
      final repo = _FakeSentencesRepository([_sentence(1), _sentence(2)], totalPages: 3);
      tester.view.physicalSize = const Size(400 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // Jak w aplikacji: strona zdań wewnątrz zewnętrznego Scaffoldu (MainShell)
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _LoggedInAuthController()),
          sentencesRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: SentencesPage())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to end'));
      await tester.pump(); // operacja + przeładowanie strony
      await tester.pump(const Duration(milliseconds: 500)); // animacja wejścia komunikatu
      return repo;
    }

    testWidgets('nie zasłania paska stron i ma krzyżyk oraz czytelny przycisk', (tester) async {
      await pumpPageWithPages(tester);

      expect(find.text('Moved to the end of the list.'), findsOneWidget);
      expect(find.text('GO TO PAGE 3'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      final snackBar = tester.getRect(find.byType(SnackBar));
      final nextButton = tester.getRect(find.text('Next'));
      expect(snackBar.bottom, lessThanOrEqualTo(nextButton.top)); // komunikat NAD paskiem stron
    });

    testWidgets('znika sam po kilku sekundach', (tester) async {
      await pumpPageWithPages(tester);
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('przycisk przenosi na ostatnią stronę', (tester) async {
      final repo = await pumpPageWithPages(tester);
      repo.loadedPages.clear();

      await tester.tap(find.text('GO TO PAGE 3'));
      await tester.pumpAndSettle();

      expect(repo.loadedPages, [3]);
    });
  });

  testWidgets('SentencesPage - przeciągnięcie za lewy uchwyt zmienia kolejność', (tester) async {
    final repo = _FakeSentencesRepository([_sentence(1), _sentence(2), _sentence(3)]);
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _LoggedInAuthController()),
        sentencesRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: SentencesPage()),
    ));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_indicator).first),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repo.reorderCalls.single.id, 1);
    final top = tester.getTopLeft(find.text('Zdanie 2')).dy;
    expect(tester.getTopLeft(find.text('Zdanie 1')).dy, greaterThan(top));
  });
}
