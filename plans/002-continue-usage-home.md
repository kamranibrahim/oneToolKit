# Plan 002: Home ranks Popular from usage and shows Continue

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**:
> `git diff --stat 3939dee..HEAD -- lib/modules/home/home_controller.dart lib/modules/home/home_view.dart lib/data/services/history_service.dart lib/core/constants/app_constants.dart lib/modules/tools/documents/notepad_view.dart test/popular_ranker_test.dart lib/core/utils/popular_ranker.dart`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none (can land before or after 001)
- **Category**: direction
- **Planned at**: commit `3939dee`, 2026-09-09

## Why this matters

A returning user already has Recents (last opened tool IDs) and Recent Activity
(last 6 actions). Popular is still a **static catalog flag mix**
(`ToolCatalog.trending` then `recommended`). Notepad notes persist in
GetStorage but never appear on home. History taps only call `openTool(tool)` —
this plan does **not** restore file inputs. It does two cheap things that
create a reason to open the app again:

1. **Continue** at the top of home: last history action + Notepad if notes exist.
2. **Popular** ranked by this device’s usage, falling back to today’s catalog flags.

## Current state

- `lib/modules/home/home_controller.dart` — `popular` is static; `recentActions` is `history.take(6)`.
- `lib/modules/home/home_view.dart` — section order: Favorites → Recents → Browse → Popular → Recent Activity.
- `lib/data/services/history_service.dart` — `recentToolIds` (max 20, most-recent first), `history` (max 100 `HistoryItem`s).
- `lib/data/models/history_item.dart` — `toolId`, `toolName`, `action`, `timestamp`, optional `detail` string. **No payload / file paths.**
- `lib/modules/tools/documents/notepad_view.dart` — notes at `AppConstants.keyNotes` (`lib/core/constants/app_constants.dart:12`), a `List` of maps with `id`, `title`, `body`, `updatedAt`.
- `lib/app/routes/app_pages.dart` — `openTool(ToolModel)` records open and `Get.toNamed(tool.route, arguments: tool)`.
- `lib/widgets/section_header.dart` — `SectionHeader(title:, actionLabel:, onAction:)`.
- `lib/widgets/tool_card.dart` — `ToolChip`, `PopularToolTile` already used on home.
- `test/widget_test.dart` — structural pattern for new unit tests.

Excerpts:

```21:31:lib/modules/home/home_controller.dart
  List<ToolModel> get popular {
    final seen = <String>{};
    final out = <ToolModel>[];
    for (final t in [...ToolCatalog.trending, ...ToolCatalog.recommended]) {
      if (!t.isAvailable || seen.contains(t.id)) continue;
      seen.add(t.id);
      out.add(t);
      if (out.length >= 8) break;
    }
    return out;
  }
```

```82:113:lib/modules/home/home_view.dart
                    if (favs.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Favorites',
                        ...
                      ),
                      ...
                    ],
                    if (recent.isNotEmpty) ...[
                      const SectionHeader(title: 'Recents'),
```

```27:41:lib/modules/tools/documents/notepad_view.dart
  void _load() {
    final raw = _storage.read(AppConstants.keyNotes);
    if (raw is! List) return;
    _notes.assignAll(
      raw.whereType<Map>().map((e) {
        ...
      }),
    );
  }
```

```234:244:lib/app/routes/app_pages.dart
Future<void> openTool(ToolModel tool) async {
  final history = Get.find<HistoryService>();
  await history.recordToolOpen(tool.id);
  if (!tool.isAvailable || tool.route == AppRoutes.comingSoon) {
    Get.toNamed(AppRoutes.comingSoon, arguments: tool);
    return;
  }
  Get.toNamed(tool.route, arguments: tool);
}
```

Notepad tool id is `'notepad'` (`lib/data/catalog/tool_catalog.dart` around line 298).

**Conventions**: Match existing home Material cards (rounded `theme.cardTheme.color`,
`AppSpace.radius`, `SectionHeader`). Do not add GetX controllers for this. Do not
add packages. Home `Obx` already tracks `favorites`, `pinned`, `recentToolIds`,
and `history.length` — if you read notes, you must also depend on something
reactive **or** read notes inside the `Obx` via `StorageService` each rebuild
(acceptable; notes change only inside Notepad, next home visit is enough).

Do **not** make notes an `.obs` list in `HomeController` unless you already have
a clean way to refresh. Reading `StorageService` when HomeView builds is enough.

## Commands you will need

| Purpose   | Command            | Expected on success |
|-----------|--------------------|---------------------|
| Analyze   | `flutter analyze`  | exit 0              |
| Tests     | `flutter test`     | all pass            |
| Single    | `flutter test test/popular_ranker_test.dart` | all pass |

## Scope

**In scope**:
- `lib/core/utils/popular_ranker.dart` (create) — pure ranking, no GetX
- `lib/modules/home/home_controller.dart` — `popular` uses ranker; add Continue getters
- `lib/modules/home/home_view.dart` — Continue section above Favorites
- `test/popular_ranker_test.dart` (create)
- `plans/README.md` — status row only

**Out of scope**:
- Changing `HistoryItem` schema / adding `payload`
- Restoring PDF/image file picks from history
- Search suggestion chips (`lib/modules/search/search_view.dart`)
- Notifications, streaks, greetings, “tool of the day”
- Catalog `isTrending` / `isRecommended` flags (keep as fallback only)
- Plan 001 widget helper (do not restyle widgets)
- New dependencies

## Git workflow

- Branch: `advisor/002-continue-usage-home`
- One or two commits. Message style:
  `Rank home Popular from local usage and surface Continue.`
- Do NOT push or open a PR unless asked.

## Steps

### Step 1: Pure ranker

Create `lib/core/utils/popular_ranker.dart`.

Required signature (names may vary, behavior must not):

```dart
List<T> rankPopular<T>({
  required List<String> recentToolIds,
  required Iterable<String> historyToolIds,
  required List<T> fallback,
  required String Function(T tool) idOf,
  required bool Function(T tool) isAvailable,
  int limit = 8,
})
```

Algorithm:

1. Score: each `historyToolIds` entry +1; each `recentToolIds` entry +2
   (opens matter more than logged actions). Missing/empty ids ignored.
2. Collect candidate ids that appear in scores, sort by score descending;
   tie-break by earlier index in `recentToolIds` (more recent open wins),
   then by stable fallback order.
3. Map ids → tools via `fallback` **plus** any scored id that exists in
   `fallback`. If a scored id is not in `fallback`, skip it (catalog is
   source of `ToolModel` instances).
4. Append unused `fallback` tools (already in trending+recommended order)
   until `limit`.
5. Skip `!isAvailable`. Unique by id.

`HomeController.popular` becomes:

```dart
List<ToolModel> get popular {
  final fallback = <ToolModel>[];
  final seen = <String>{};
  for (final t in [...ToolCatalog.trending, ...ToolCatalog.recommended]) {
    if (!t.isAvailable || seen.contains(t.id)) continue;
    seen.add(t.id);
    fallback.add(t);
  }
  return rankPopular<ToolModel>(
    recentToolIds: history.recentToolIds.toList(),
    historyToolIds: history.history.map((e) => e.toolId),
    fallback: fallback,
    idOf: (t) => t.id,
    isAvailable: (t) => t.isAvailable,
    limit: 8,
  );
}
```

When `recentToolIds` and `history` are empty, result **must equal** today’s
popular list (first 8 unique trending+recommended available tools).

**Verify**: file exists; `flutter analyze lib/core/utils/popular_ranker.dart`
reports nothing.

### Step 2: Continue getters on HomeController

Add (names may vary):

```dart
HistoryItem? get continueAction =>
    history.history.isEmpty ? null : history.history.first;

bool get hasNotes {
  final raw = Get.find<StorageService>().read(AppConstants.keyNotes);
  return raw is List && raw.isNotEmpty;
}

int get noteCount {
  final raw = Get.find<StorageService>().read(AppConstants.keyNotes);
  if (raw is! List) return 0;
  return raw.length;
}

bool get showContinue => continueAction != null || hasNotes;
```

Import `StorageService` and `AppConstants`. Do not put notes into HistoryService.

**Verify**: `flutter analyze lib/modules/home/` → no issues.

### Step 3: Continue UI on home

In `home_view.dart`, inside the `Obx` `ContainedSliverList` **children**, insert
**before** the Favorites block:

- If `controller.showContinue`:
  - `SectionHeader(title: 'Continue')`
  - A `Material` card matching Recent Activity (same padding, icon, chevron,
    divider if two rows):

  **Row A** (if `continueAction != null`):
  - Icon from `ToolCatalog.byId(item.toolId)?.icon` (same as Recent Activity)
  - Title: `item.toolName`
  - Subtitle: `item.detail == null ? item.action : '${item.action} · ${item.detail}'`
  - `onTap`: `openTool(tool)` when tool exists, else no-op

  **Row B** (if `hasNotes`):
  - Icon: notepad tool’s icon (`ToolCatalog.byId('notepad')`)
  - Title: `Notepad`
  - Subtitle: `'$noteCount notes'` (or `'1 note'` when count == 1)
  - `onTap`: `openTool` for notepad

Do not duplicate the entire Recent Activity list here. Continue is 1–2 rows.
Keep Recent Activity at the bottom unchanged.

Match existing `InkWell` / `BorderRadius` / `Divider(indent: 58)` from
`home_view.dart` lines 132–212. Extract a private `_ContinueRow` widget in
`home_view.dart` if it avoids copy-paste; do not create a new file under
`lib/widgets/` unless the file would otherwise exceed ~80 new lines of
duplication.

**Verify**: `flutter analyze` → exit 0. Visually, section order is:

Search → **Continue** (if any) → Favorites → Recents → Browse → Popular → Recent Activity.

### Step 4: Tests

Create `test/popular_ranker_test.dart`. Use a tiny fake:

```dart
class _T {
  _T(this.id, {this.available = true});
  final String id;
  final bool available;
}
```

Cases:

1. **Empty usage** — `recentToolIds: []`, `historyToolIds: []`, fallback
   `[a,b,c]` → `[a,b,c]` (same order).
2. **Usage wins** — recent `['z']`, fallback `[a,b]`, and `z` is **also** in
   fallback as last item → `z` is first, then `a`, `b` (unique).
3. **History vs recent weights** — history many `a`, recent one `b`; both in
   fallback → `b` outranks `a` because recent is +2 vs +1 per history hit
   *unless* you construct history so `a` has enough hits to beat `b`. Write
   one test that documents the actual winner for: history `['a','a','a']`
   (score 3) vs recent `['b']` (score 2) → `a` first. And one where recent
   `['b']` + history `['b']` (score 3) vs history-only `['a','a']` (score 2)
   → `b` first.
4. **Unavailable skipped** — scored id whose `isAvailable` is false is omitted.
5. **Limit** — `limit: 2` returns length ≤ 2.
6. **Unknown scored id** — history mentions `'ghost'` not in fallback → ignored,
   no throw.

**Verify**: `flutter test test/popular_ranker_test.dart` → all pass.
Then `flutter test` → all pass.

## Test plan

- New: `test/popular_ranker_test.dart` (cases above).
- Pattern: `test/widget_test.dart`.
- No golden/widget test for HomeView unless you can do it without pumping the
  full GetX app. Do not add a flaky widget test. Ranking is the regression net.

## Done criteria

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0; new ranker tests exist and pass
- [ ] Empty usage → Popular order identical to previous trending+recommended fill
- [ ] Home shows Continue only when last action or notes exist
- [ ] Continue notepad row hidden when `keyNotes` is missing/empty
- [ ] `HistoryItem` JSON shape unchanged (`toJson` / `fromJson` not modified)
- [ ] No files outside the in-scope list are modified
- [ ] `plans/README.md` status row for 002 is `DONE`

## STOP conditions

- `HomeController.popular` or home section order already rewritten (drift).
- Notes are no longer stored at `AppConstants.keyNotes` as a `List`.
- You feel you must add `payload` to `HistoryItem` to “make Continue useful.”
  **Do not.** Open the tool only.
- Verification fails twice.
- You need to edit `search_view.dart`, notifications, or catalog flags.

## Maintenance notes

- Next habit plan (not this one): optional `HistoryItem.payload` for merge/notepad
  drafts. Continue UI can grow a “3 files” resume once that exists.
- If Popular starts feeling jumpy, dampen scores (e.g. recency decay). Keep the
  function pure so tests stay cheap.
- Reviewer: first-run home must look the same as today (no empty Continue
  header, Popular still filled from catalog flags).
