# Plan 001: Pin tools appear first on the home-screen widget

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**:
> `git diff --stat 3939dee..HEAD -- lib/data/services/favorites_service.dart lib/data/services/widget_sync_service.dart lib/modules/home/home_controller.dart test/shortcut_ids_test.dart`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: direction
- **Planned at**: commit `3939dee`, 2026-09-09

## Why this matters

Home already prefers **pinned** tools (`HomeController.favoriteTools`). The
home-screen widget ignores pins and writes `favorites.take(4)`. A user who pins
Calculator / Notepad / Merge PDF still sees whatever they starred first. That
breaks the mental model “my top tools everywhere” and wastes the only OS-level
re-entry surface the app has.

After this plan, widget slots 0–3 are: pinned IDs in pin order, then remaining
favorites in favorites-list order, unique, max 4.

## Current state

- `lib/data/services/favorites_service.dart` — two lists: `favorites` and `pinned`. Pin auto-adds to favorites. Every persist calls `WidgetSyncService.syncFavorites()`.
- `lib/data/services/widget_sync_service.dart` — writes first 4 **favorites** only.
- `lib/modules/home/home_controller.dart` — home chips already use pinned first. **Do not change home chip behavior** except optionally calling the same helper (allowed, not required).
- `test/widget_test.dart` — catalog unit tests only; use that file as the test style (plain `test()`, `package:one_toolkit/...` imports, no GetX).

Excerpts:

```56:59:lib/data/services/widget_sync_service.dart
  Future<void> syncFavorites() async {
    try {
      final favorites = Get.find<FavoritesService>();
      final ids = favorites.favorites.take(4).toList();
```

```13:17:lib/modules/home/home_controller.dart
  List<ToolModel> get favoriteTools {
    final pinned = favorites.pinnedTools();
    if (pinned.isNotEmpty) return pinned;
    return favorites.favoriteTools();
  }
```

```38:46:lib/data/services/favorites_service.dart
  Future<void> togglePin(String toolId) async {
    if (pinned.contains(toolId)) {
      pinned.remove(toolId);
    } else {
      if (!favorites.contains(toolId)) favorites.add(toolId);
      pinned.add(toolId);
    }
    await _persist();
  }
```

**Conventions**: Dart, GetX services, no new packages. Tests live under `test/`
and import `package:one_toolkit/...`. Commit messages are imperative sentences
with a period (example: `Fix release APK signing path and ML Kit R8 rules.`).

## Commands you will need

| Purpose   | Command            | Expected on success      |
|-----------|--------------------|--------------------------|
| Analyze   | `flutter analyze`  | exit 0, no issues        |
| Tests     | `flutter test`     | all pass                 |
| Single    | `flutter test test/shortcut_ids_test.dart` | all pass |

## Scope

**In scope**:
- `lib/core/utils/shortcut_ids.dart` (create) — pure function, no GetX
- `lib/data/services/favorites_service.dart` — add a thin wrapper that calls the helper
- `lib/data/services/widget_sync_service.dart` — use the wrapper instead of `favorites.take(4)`
- `test/shortcut_ids_test.dart` (create)
- `plans/README.md` — status row only

**Out of scope**:
- Native widget layouts (`FavoritesWidget.swift`, `FavoritesWidgetProvider.kt`)
- Home Favorites chip section UI
- Reordering pins (there is no `reorderPinned` today — do not add it)
- Plan 002 / 003 files
- New dependencies

## Git workflow

- Branch: `advisor/001-pin-widget-parity`
- One commit is enough. Message style:
  `Show pinned tools first on the home-screen widget.`
- Do NOT push or open a PR unless asked.

## Steps

### Step 1: Add a pure merge helper

Create `lib/core/utils/shortcut_ids.dart`:

```dart
/// Pinned IDs first (pin order), then remaining favorites (list order).
/// Empty IDs skipped. Unique. Truncated to [limit].
List<String> shortcutIds({
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
```

Add on `FavoritesService`:

```dart
List<String> shortcutIds({int limit = 4}) =>
    shortcutIds(pinned: pinned, favorites: favorites, limit: limit);
```

**Name clash**: the instance method and the top-level function cannot share a
name if both are imported. Either:

- name the top-level function `mergeShortcutIds`, and the method `shortcutIds`, or
- prefix the import: `import '.../shortcut_ids.dart' as shortcuts;` then
  `shortcuts.shortcutIds(...)`.

Prefer `mergeShortcutIds` as the top-level name.

**Verify**: `dart analyze lib/core/utils/shortcut_ids.dart` → no errors
(or `flutter analyze` if `dart` is not on PATH).

### Step 2: Point widget sync at the helper

In `WidgetSyncService.syncFavorites`, replace:

```dart
final ids = favorites.favorites.take(4).toList();
```

with:

```dart
final ids = favorites.shortcutIds(limit: 4);
```

Leave name lookup, padding `names` to 4, and `HomeWidget.saveWidgetData` unchanged.

**Verify**: `rg "favorites.take\\(4\\)" lib/` → no matches.

### Step 3: Unit tests

Create `test/shortcut_ids_test.dart` modeled on `test/widget_test.dart`
(plain `void main()`, `group`, `test`, `expect`). Cover:

1. Empty pinned + empty favorites → `[]`
2. Empty pinned + four favorites → those four in order
3. Two pins + many favorites → pins first, then next unpinned favorites, length 4
4. Pin that is also in favorites → appears once (pin position)
5. `limit: 2` truncates
6. Empty-string IDs are skipped

**Verify**: `flutter test test/shortcut_ids_test.dart` → all pass.

### Step 4: Analyze full project

**Verify**: `flutter analyze` → exit 0. `flutter test` → all pass.

## Test plan

- New file: `test/shortcut_ids_test.dart` (cases listed in Step 3).
- Pattern: `test/widget_test.dart`.
- No widget/integration test for the native home-screen widget — that is
  README smoke-test work, out of scope.

## Done criteria

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0; `test/shortcut_ids_test.dart` exists and passes
- [ ] `rg "favorites\\.take\\(4\\)" lib/` returns no matches
- [ ] `WidgetSyncService.syncFavorites` uses `FavoritesService.shortcutIds`
- [ ] No files outside the in-scope list are modified (`git status`)
- [ ] `plans/README.md` status row for 001 is `DONE`

## STOP conditions

- The excerpts in "Current state" no longer match (especially
  `favorites.take(4)` already gone, or pin/favorite storage split removed).
- `syncFavorites` starts writing a different widget payload shape
  (`tool_0` / `tool_id_0` …). Do not change the native contract.
- A step's verification fails twice after a reasonable fix.
- The fix appears to require editing Swift/Kotlin widget files.

## Maintenance notes

- Native widgets still read `tool_0`…`tool_3` and `tool_id_*`. Changing those
  keys requires a coordinated iOS + Android update.
- If pin reorder is added later, `mergeShortcutIds` already respects list order
  — persist pin order and the widget follows.
- Reviewer: confirm pins win over earlier-starred favorites, and that unpinning
  does not leave a hole (fill from favorites).
