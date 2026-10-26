/// Wynik przeniesienia elementu na liście (drag & drop).
class ReorderResult<T> {
  /// Lista po przeniesieniu (nowa instancja).
  final List<T> items;

  /// Przeniesiony element.
  final T moved;

  /// Element bezpośrednio nad nową pozycją (`null` = początek listy).
  final T? previous;

  /// Element bezpośrednio pod nową pozycją (`null` = koniec listy).
  final T? next;

  const ReorderResult({
    required this.items,
    required this.moved,
    required this.previous,
    required this.next,
  });
}

/// Przenosi element z [oldIndex] na [newIndex] i wyznacza sąsiadów dla API.
///
/// Indeksy jak w `ReorderableListView.onReorderItem` (newIndex już skorygowany
/// o usunięty element). Zwraca `null`, gdy pozycja się nie zmienia.
ReorderResult<T>? reorderList<T>(List<T> items, int oldIndex, int newIndex) {
  if (oldIndex == newIndex ||
      oldIndex < 0 ||
      oldIndex >= items.length ||
      newIndex < 0 ||
      newIndex >= items.length) {
    return null;
  }

  final reordered = List<T>.of(items);
  final moved = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, moved);

  return ReorderResult(
    items: reordered,
    moved: moved,
    previous: newIndex > 0 ? reordered[newIndex - 1] : null,
    next: newIndex < reordered.length - 1 ? reordered[newIndex + 1] : null,
  );
}
