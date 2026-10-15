/// Rank popular tools by local usage, then fill from [fallback] order.
List<T> rankPopular<T>({
  required List<String> recentToolIds,
  required Iterable<String> historyToolIds,
  required List<T> fallback,
  required String Function(T tool) idOf,
  required bool Function(T tool) isAvailable,
  int limit = 8,
}) {
  final scores = <String, int>{};
  void addScore(String id, int delta) {
    if (id.isEmpty) return;
    scores[id] = (scores[id] ?? 0) + delta;
  }

  for (final id in historyToolIds) {
    addScore(id, 1);
  }
  for (final id in recentToolIds) {
    addScore(id, 2);
  }

  final fallbackById = <String, T>{};
  final fallbackIndex = <String, int>{};
  for (var i = 0; i < fallback.length; i++) {
    final tool = fallback[i];
    final id = idOf(tool);
    if (id.isEmpty || fallbackById.containsKey(id)) continue;
    fallbackById[id] = tool;
    fallbackIndex[id] = i;
  }

  final recentIndex = <String, int>{};
  for (var i = 0; i < recentToolIds.length; i++) {
    final id = recentToolIds[i];
    if (id.isEmpty || recentIndex.containsKey(id)) continue;
    recentIndex[id] = i;
  }

  final scoredIds = scores.keys.toList()
    ..sort((a, b) {
      final byScore = scores[b]!.compareTo(scores[a]!);
      if (byScore != 0) return byScore;
      final ra = recentIndex[a] ?? 1 << 30;
      final rb = recentIndex[b] ?? 1 << 30;
      if (ra != rb) return ra.compareTo(rb);
      final fa = fallbackIndex[a] ?? 1 << 30;
      final fb = fallbackIndex[b] ?? 1 << 30;
      return fa.compareTo(fb);
    });

  final seen = <String>{};
  final out = <T>[];

  void tryAdd(String id) {
    if (out.length >= limit || id.isEmpty || seen.contains(id)) return;
    final tool = fallbackById[id];
    if (tool == null || !isAvailable(tool)) return;
    seen.add(id);
    out.add(tool);
  }

  for (final id in scoredIds) {
    tryAdd(id);
    if (out.length >= limit) return out;
  }
  for (final tool in fallback) {
    tryAdd(idOf(tool));
    if (out.length >= limit) return out;
  }
  return out;
}
