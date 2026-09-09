import 'package:flutter_test/flutter_test.dart';
import 'package:one_toolkit/core/utils/popular_ranker.dart';

class _T {
  const _T(this.id, {this.available = true});

  final String id;
  final bool available;
}

List<_T> rank({
  List<String> recent = const [],
  Iterable<String> history = const [],
  required List<_T> fallback,
  int limit = 8,
}) {
  return rankPopular<_T>(
    recentToolIds: recent,
    historyToolIds: history,
    fallback: fallback,
    idOf: (t) => t.id,
    isAvailable: (t) => t.available,
    limit: limit,
  );
}

void main() {
  group('rankPopular', () {
    test('empty usage returns fallback order', () {
      const fallback = [_T('a'), _T('b'), _T('c')];
      expect(rank(fallback: fallback).map((t) => t.id), ['a', 'b', 'c']);
    });

    test('recent id last in fallback is ranked first', () {
      const fallback = [_T('a'), _T('b'), _T('z')];
      expect(
        rank(recent: const ['z'], fallback: fallback).map((t) => t.id),
        ['z', 'a', 'b'],
      );
    });

    test('three history hits beat one recent', () {
      const fallback = [_T('a'), _T('b')];
      expect(
        rank(
          recent: const ['b'],
          history: const ['a', 'a', 'a'],
          fallback: fallback,
        ).map((t) => t.id),
        ['a', 'b'],
      );
    });

    test('recent plus history beats two history hits', () {
      const fallback = [_T('a'), _T('b')];
      expect(
        rank(
          recent: const ['b'],
          history: const ['b', 'a', 'a'],
          fallback: fallback,
        ).map((t) => t.id),
        ['b', 'a'],
      );
    });

    test('unavailable scored id is omitted', () {
      const fallback = [_T('a'), _T('b', available: false), _T('c')];
      expect(
        rank(recent: const ['b'], fallback: fallback).map((t) => t.id),
        ['a', 'c'],
      );
    });

    test('limit 2 truncates', () {
      const fallback = [_T('a'), _T('b'), _T('c')];
      expect(
        rank(fallback: fallback, limit: 2).map((t) => t.id),
        ['a', 'b'],
      );
    });

    test('ghost history id is ignored', () {
      const fallback = [_T('a'), _T('b')];
      expect(
        () => rank(
          history: const ['ghost'],
          fallback: fallback,
        ),
        returnsNormally,
      );
      expect(
        rank(history: const ['ghost'], fallback: fallback).map((t) => t.id),
        ['a', 'b'],
      );
    });
  });
}
