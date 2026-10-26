import 'package:flutter_test/flutter_test.dart';
import 'package:maia_flutter_client/features/projects/domain/list_reorder.dart';

void main() {
  const items = ['A', 'B', 'C', 'D'];

  group('reorderList', () {
    test('moves item down and finds both neighbours', () {
      final result = reorderList(items, 0, 2)!;

      expect(result.items, ['B', 'C', 'A', 'D']);
      expect(result.moved, 'A');
      expect(result.previous, 'C');
      expect(result.next, 'D');
    });

    test('moving to the top has no previous neighbour', () {
      final result = reorderList(items, 3, 0)!;

      expect(result.items, ['D', 'A', 'B', 'C']);
      expect(result.previous, isNull);
      expect(result.next, 'A');
    });

    test('moving to the bottom has no next neighbour', () {
      final result = reorderList(items, 1, 3)!;

      expect(result.items, ['A', 'C', 'D', 'B']);
      expect(result.previous, 'D');
      expect(result.next, isNull);
    });

    test('returns null when position does not change or index is invalid', () {
      expect(reorderList(items, 1, 1), isNull);
      expect(reorderList(items, -1, 2), isNull);
      expect(reorderList(items, 0, 4), isNull);
    });

    test('does not mutate the original list', () {
      final original = List.of(items);

      reorderList(original, 0, 3);

      expect(original, items);
    });
  });
}
