/// Pinned IDs first (pin order), then remaining favorites (list order).
/// Empty IDs skipped. Unique. Truncated to [limit].
List<String> mergeShortcutIds({
  required List<String> pinned,
  required List<String> favorites,
  int limit = 4,
}) {
  final seen = <String>{};
  final out = <String>[];
  for (final id in [...pinned, ...favorites]) {
    if (id.isEmpty || seen.contains(id)) continue;
    seen.add(id);
    out.add(id);
    if (out.length >= limit) break;
  }
  return out;
}
