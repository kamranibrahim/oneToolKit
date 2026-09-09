import 'package:flutter_test/flutter_test.dart';
import 'package:one_toolkit/core/utils/shortcut_ids.dart';

void main() {
  group('mergeShortcutIds', () {
    test('empty pinned and empty favorites yields empty list', () {
      expect(
        mergeShortcutIds(pinned: const [], favorites: const []),
        isEmpty,
      );
    });

    test('empty pinned returns first four favorites in order', () {
      expect(
        mergeShortcutIds(
          pinned: const [],
          favorites: const ['a', 'b', 'c', 'd'],
        ),
        ['a', 'b', 'c', 'd'],
      );
    });

    test('pins first then remaining favorites, length 4', () {
      expect(
        mergeShortcutIds(
          pinned: const ['pin1', 'pin2'],
          favorites: const ['a', 'b', 'c', 'd', 'e'],
        ),
        ['pin1', 'pin2', 'a', 'b'],
      );
    });

    test('pin also in favorites appears once at pin position', () {
      expect(
        mergeShortcutIds(
          pinned: const ['b'],
          favorites: const ['a', 'b', 'c', 'd'],
        ),
        ['b', 'a', 'c', 'd'],
      );
    });

    test('limit 2 truncates', () {
      expect(
        mergeShortcutIds(
          pinned: const ['pin1'],
          favorites: const ['a', 'b', 'c'],
          limit: 2,
        ),
        ['pin1', 'a'],
      );
    });

    test('empty-string IDs are skipped', () {
      expect(
        mergeShortcutIds(
          pinned: const ['', 'pin1'],
          favorites: const ['', 'a', 'b'],
        ),
        ['pin1', 'a', 'b'],
      );
    });
  });
}
