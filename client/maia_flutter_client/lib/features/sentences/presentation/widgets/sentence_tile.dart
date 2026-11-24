import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sentence_model.dart';
import '../delete_sentence_controller.dart';
import '../sentences_provider.dart';
import 'sentence_form_dialog.dart';

enum _SentenceAction { edit, moveToTop, moveToBottom, delete }

/// Kafelek zdania na liście "My Sentences".
///
/// Układ jak w Daily Tasks / Projects: uchwyt przeciągania po lewej, rzadziej używane
/// akcje w menu "⋮". Tekst po angielsku jest domyślnie rozmyty (tryb nauki) -
/// odkrywa go przycisk z okiem albo dotknięcie rozmytego tekstu.
class SentenceTile extends ConsumerStatefulWidget {
  final Sentence sentence;

  /// Pozycja na bieżącej stronie - potrzebna uchwytowi przeciągania.
  final int index;
  final bool isFirstOverall;
  final bool isLastOverall;

  const SentenceTile({
    super.key,
    required this.sentence,
    required this.index,
    this.isFirstOverall = false,
    this.isLastOverall = false,
  });

  @override
  ConsumerState<SentenceTile> createState() => _SentenceTileState();
}

class _SentenceTileState extends ConsumerState<SentenceTile> {
  // Domyślnie ukryty - żeby przy nauce nie podglądać odpowiedzi
  bool _isEnglishRevealed = false;

  void _toggleEnglish() => setState(() => _isEnglishRevealed = !_isEnglishRevealed);

  void _onAction(_SentenceAction action) {
    switch (action) {
      case _SentenceAction.edit:
        showDialog(
          context: context,
          builder: (context) => SentenceFormDialog(sentence: widget.sentence),
        );
      case _SentenceAction.moveToTop:
        _move(toTop: true);
      case _SentenceAction.moveToBottom:
        _move(toTop: false);
      case _SentenceAction.delete:
        _showDeleteConfirmation();
    }
  }

  Future<void> _move({required bool toTop}) async {
    // Pobieramy zależności przed await: po przeładowaniu strony ten kafelek może zniknąć
    final notifier = ref.read(sentencesProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.sentence.id;

    final success = toTop ? await notifier.moveToTop(id) : await notifier.moveToBottom(id);
    final state = ref.read(sentencesProvider);

    messenger.hideCurrentSnackBar();
    if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? "Failed to move the sentence."), backgroundColor: Colors.red),
      );
      return;
    }

    final targetPage = toTop ? 1 : state.totalPages;
    final isTargetVisible = state.currentPage == targetPage;
    messenger.showSnackBar(
      SnackBar(
        content: Text(toTop ? "Moved to the top of the list." : "Moved to the end of the list."),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: isTargetVisible
            ? null
            : SnackBarAction(
                label: "SHOW",
                onPressed: () => notifier.loadSentences(page: targetPage),
              ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Sentence"),
        content: const Text("Are you sure you want to delete this sentence?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              // 1. Najpierw zamykamy dialog, 2. delegujemy operację do kontrolera
              Navigator.of(ctx).pop();
              ref
                  .read(deleteSentenceControllerProvider)
                  .deleteSentence(context: context, sentenceId: widget.sentence.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentence;
    final hideOriginal = sentence.hidesOriginalText && !_isEnglishRevealed;
    final hideTranslation = !sentence.hidesOriginalText && !_isEnglishRevealed;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ConstrainedBox(
          // Zawsze jest miejsce na menu i oko jedno pod drugim
          constraints: const BoxConstraints(minHeight: 2 * _actionSize),
          child: Stack(
            children: [
              _buildContentRow(sentence, hideOriginal, hideTranslation),
              // Kolumna akcji nałożona na zarezerwowane miejsce po prawej - zna wysokość kafelka,
              // więc może ustawić oko na środku (patrz _buildActions)
              Positioned(top: 0, bottom: 0, right: 0, width: _actionSize, child: _buildActions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentRow(Sentence sentence, bool hideOriginal, bool hideTranslation) {
    return Row(
      // Uchwyt wyśrodkowany w pionie względem całego kafelka
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // --- Uchwyt przeciągania: zawsze po lewej (jak w Daily Tasks i Projects) ---
        // Wąski (mały poziomy margines), żeby zostawić jak najwięcej miejsca na tekst
        ReorderableDragStartListener(
          index: widget.index,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            child: Icon(Icons.drag_indicator, color: Colors.grey),
          ),
        ),

        // --- Treść ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 0, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HideableText(
                  text: sentence.originalText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  isHidden: hideOriginal,
                  onReveal: _toggleEnglish,
                ),
                const SizedBox(height: 4),
                _HideableText(
                  text: sentence.translatedText,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                  isHidden: hideTranslation,
                  onReveal: _toggleEnglish,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.language, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${sentence.sourceLanguage}:${sentence.targetLanguage}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Miejsce na kolumnę akcji (menu + oko), nakładaną w build()
        const SizedBox(width: _actionSize),
      ],
    );
  }

  /// Menu w prawym górnym rogu, oko na środku wysokości kafelka.
  /// Przy niskim kafelku oko nie wchodzi na menu - staje tuż pod nim.
  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centeredTop = (constraints.maxHeight - _actionSize) / 2;
        final eyeTop = centeredTop < _actionSize ? _actionSize : centeredTop;
        return Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, child: _buildMenu()),
            Positioned(
              top: eyeTop,
              left: 0,
              right: 0,
              child: IconButton(
                tooltip: _isEnglishRevealed ? "Hide English" : "Show English",
                onPressed: _toggleEnglish,
                style: _compactIconStyle,
                iconSize: _compactIconSize,
                icon: Icon(
                  _isEnglishRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Kompaktowe przyciski (36 px zamiast domyślnych 48) - więcej miejsca na tekst na wąskich ekranach
  static const double _actionSize = 36;
  static const double _compactIconSize = 20;
  static final ButtonStyle _compactIconStyle = IconButton.styleFrom(
    fixedSize: const Size.square(_actionSize),
    minimumSize: const Size.square(_actionSize),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  // --- Rzadziej używane akcje ---
  Widget _buildMenu() {
    return PopupMenuButton<_SentenceAction>(
      tooltip: 'More actions',
      style: _compactIconStyle,
      iconSize: _compactIconSize,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: _onAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _SentenceAction.edit,
          child: _MenuRow(icon: Icons.edit, label: "Edit"),
        ),
        PopupMenuItem(
          value: _SentenceAction.moveToTop,
          enabled: !widget.isFirstOverall,
          child: const _MenuRow(icon: Icons.vertical_align_top, label: "Move to top"),
        ),
        PopupMenuItem(
          value: _SentenceAction.moveToBottom,
          enabled: !widget.isLastOverall,
          child: const _MenuRow(icon: Icons.vertical_align_bottom, label: "Move to end"),
        ),
        PopupMenuItem(
          value: _SentenceAction.delete,
          child: _MenuRow(icon: Icons.delete, label: "Delete", color: Colors.red.shade700),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}

/// Tekst, który można rozmyć. Rozmyty tekst nie jest czytany przez czytniki ekranu
/// (inaczej "podpowiadałby" odpowiedź) i odkrywa się po dotknięciu.
class _HideableText extends StatelessWidget {
  static const double _blurSigma = 6;

  final String text;
  final TextStyle style;
  final bool isHidden;
  final VoidCallback onReveal;

  const _HideableText({required this.text, required this.style, required this.isHidden, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(text, style: style);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: isHidden ? _blurSigma : 0),
      duration: const Duration(milliseconds: 200),
      child: textWidget,
      builder: (context, sigma, child) {
        if (sigma == 0) return child!;
        final blurred = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
          child: child,
        );
        if (!isHidden) return blurred; // w trakcie animacji odkrywania
        return Semantics(
          button: true,
          label: "Hidden text. Tap to reveal.",
          child: ExcludeSemantics(
            child: GestureDetector(onTap: onReveal, behavior: HitTestBehavior.opaque, child: blurred),
          ),
        );
      },
    );
  }
}
