# Plan 003: Share files into OneToolkit from other apps

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**:
> `git diff --stat 3939dee..HEAD -- android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/kamranibrahim/onetoolkit/MainActivity.kt ios/Runner/AppDelegate.swift ios/Runner/SceneDelegate.swift ios/Runner/Info.plist lib/main.dart lib/app/routes/app_pages.dart lib/modules/tools/pdf/pdf_merge_view.dart lib/modules/tools/images/image_compress_view.dart lib/modules/tools/images/images_to_pdf_view.dart lib/data/services/widget_sync_service.dart`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.
>
> Also run `git diff HEAD -- android/app/src/main/AndroidManifest.xml`.
> At plan time the working tree may already have **uncommitted** manifest
> edits. If the live file already contains `ACTION_SEND`, STOP and report.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: none
- **Category**: direction
- **Planned at**: commit `3939dee`, 2026-09-09

## Why this matters

OneToolkit can **share out** (`share_plus` via `lib/core/utils/share_helper.dart`)
but cannot receive files. Users must remember the app, then re-pick the same
PDF/photo. Utility apps that sit on the OS share sheet get opened every time
someone has a file. That is the main habit loop this product is missing.

This plan adds inbound share for **PDF and images only**, routes them to an
existing tool, and preloads the files. No new catalog tools. No default-PDF
handler (`ACTION_VIEW`) — that steals system PDF opens.

## Current state

- `android/app/src/main/AndroidManifest.xml` — `MAIN` + `onetoolkit://tool` VIEW only. Camera + INTERNET. Broad media permissions are **explicitly removed** (Play policy). Do not add `READ_MEDIA_*`.
- `android/app/src/main/kotlin/com/kamranibrahim/onetoolkit/MainActivity.kt` — empty `FlutterActivity`.
- `android/.../MainActivity` `launchMode` is `singleTop` (good for `onNewIntent`).
- `ios/Runner/Info.plist` — URL scheme `onetoolkit` only. No share extension.
- `ios/Runner/AppDelegate.swift` — Flutter implicit engine; no method channels.
- `ios/FavoritesWidget/` + `ios/scripts/add_favorites_widget.rb` — **pattern** for adding an app extension with App Group `group.com.kamranibrahim.onetoolkit`.
- `lib/main.dart` — services registered; post-frame `WidgetSyncService.bindLaunchHandlers()`.
- `lib/app/routes/app_pages.dart` — `openTool` passes `ToolModel` as arguments; tool screens **ignore** arguments today (`Get.arguments` unused except coming-soon / category).
- `lib/modules/tools/pdf/pdf_merge_view.dart` — local `List<PlatformFile> _files`; picker `FileType.custom` pdf.
- `lib/modules/tools/images/image_compress_view.dart` — one `XFile? _original` from gallery.
- `lib/modules/tools/images/images_to_pdf_view.dart` — `List<XFile> _images`.
- `lib/modules/onboarding/onboarding_view.dart` — first run can land on onboarding before shell.
- No `receive_sharing_intent` / `app_links` package. **Do not add those packages.** Use a MethodChannel you own.

Excerpts:

```34:43:android/app/src/main/AndroidManifest.xml
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                ...
                <data android:scheme="onetoolkit" android:host="tool"/>
            </intent-filter>
```

```1:5:android/app/src/main/kotlin/com/kamranibrahim/onetoolkit/MainActivity.kt
package com.kamranibrahim.onetoolkit

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

```27:30:lib/main.dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(widgets.bindLaunchHandlers());
  });
```

**Conventions**: GetX services in `lib/data/services/`, registered `permanent: true` in `main.dart`. Tool UIs are `StatefulWidget` + `ToolScaffold`. Share-out helper stays outbound-only. Commit style: `Accept shared PDFs and images into existing tools.`

## Commands you will need

| Purpose   | Command            | Expected on success |
|-----------|--------------------|---------------------|
| Analyze   | `flutter analyze`  | exit 0              |
| Tests     | `flutter test`     | all pass            |
| Android compile (optional smoke) | `flutter build apk --debug` | exit 0 (slow; run if Kotlin/manifest changed) |

## Suggested executor toolkit

- Android share intents: https://developer.android.com/training/sharing/receive
- Copy the **structure** of `ios/scripts/add_favorites_widget.rb` for the iOS target (do not copy widget Swift).
- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels

## Scope

**In scope**:
- `lib/core/utils/share_router.dart` (create) — MIME → tool ids
- `lib/data/models/shared_file.dart` (create) — `path` + `mime`
- `lib/data/services/pending_share_service.dart` (create)
- `lib/modules/share/share_target_sheet.dart` (create) — bottom sheet chooser
- `lib/main.dart` — register service; bind after first frame
- `lib/modules/onboarding/onboarding_view.dart` — one call after leaving onboarding
- `lib/modules/tools/pdf/pdf_merge_view.dart` — preload PDFs
- `lib/modules/tools/images/image_compress_view.dart` — preload one image
- `lib/modules/tools/images/images_to_pdf_view.dart` — preload images
- `android/app/src/main/AndroidManifest.xml` — SEND / SEND_MULTIPLE filters only
- `android/app/src/main/kotlin/com/kamranibrahim/onetoolkit/MainActivity.kt`
- iOS (second half, after Android works):
  - `ios/ShareExtension/` sources + `ios/scripts/add_share_extension.rb`
  - `ios/Runner/AppDelegate.swift` and/or `SceneDelegate.swift` — channel + URL
  - `ios/Runner/Runner.entitlements` — App Group already expected; do not change the group id
- `test/share_router_test.dart` (create)
- `plans/README.md` — status row

**Out of scope**:
- `ACTION_VIEW` / becoming the default PDF or image viewer
- New media-library permissions
- OCR / compress-PDF / watermark as share targets (can add later via `share_router.dart` only)
- Text / URL / WiFi share
- `receive_sharing_intent`, `app_links`, or any new pub dependency
- Cloud upload
- Changing `openTool` argument type away from `ToolModel`
- Plan 001 / 002 home/widget work

## Git workflow

- Branch: `advisor/003-share-in`
- Commits: (1) Dart router + service + tests, (2) Android + tool preload, (3) iOS extension if reached.
- Message style: `Accept shared PDFs and images into existing tools.`
- Do NOT push or open a PR unless asked.

## Steps

### Step 1: Pure router + tests (do this first)

Create `lib/core/utils/share_router.dart`.

```dart
class ShareKind { static const pdf = 'pdf'; static const image = 'image'; static const other = 'other'; }

String shareKind(String mime) {
  final m = mime.toLowerCase();
  if (m == 'application/pdf' || m.endsWith('/pdf')) return ShareKind.pdf;
  if (m.startsWith('image/')) return ShareKind.image;
  return ShareKind.other;
}

/// Suggested tool ids, first is the default.
List<String> suggestedToolIds(Iterable<String> mimes) {
  var pdf = 0;
  var image = 0;
  for (final m in mimes) {
    final k = shareKind(m);
    if (k == ShareKind.pdf) pdf++;
    if (k == ShareKind.image) image++;
  }
  if (pdf == 0 && image == 0) return const [];
  if (pdf > 0 && image == 0) return const ['pdf_merge'];
  if (image > 0 && pdf == 0) {
    if (image == 1) return const ['image_compress', 'images_to_pdf', 'ai_ocr'];
    return const ['images_to_pdf', 'image_compress'];
  }
  return const ['pdf_merge', 'images_to_pdf'];
}
```

`ai_ocr` may be listed for a **single image**. You do **not** have to preload
OCR in this plan. If the user picks OCR, `openTool` is enough (they re-pick
once). Preload is required only for `pdf_merge`, `image_compress`, `images_to_pdf`.

Tests in `test/share_router_test.dart` (pattern: `test/widget_test.dart`):

1. `[]` → `[]`
2. one `application/pdf` → `['pdf_merge']`
3. two PDFs → `['pdf_merge']`
4. one `image/jpeg` → starts with `image_compress`, includes `images_to_pdf` and `ai_ocr`
5. two `image/png` → starts with `images_to_pdf`, no `ai_ocr`
6. mixed pdf + image → both `pdf_merge` and `images_to_pdf`
7. `text/plain` only → `[]`

**Verify**: `flutter test test/share_router_test.dart` → all pass.

### Step 2: PendingShareService + chooser

`lib/data/models/shared_file.dart`:

```dart
class SharedFile {
  const SharedFile({required this.path, required this.mime});
  final String path;
  final String mime;
}
```

`lib/data/services/pending_share_service.dart` as a `GetxService`:

- `final pending = <SharedFile>[].obs;`
- Channel name (exact): `com.kamranibrahim.onetoolkit/share`
- `Future<void> pullFromNative()` — `invokeMethod('takePending')` expecting
  `List` of maps `{path: String, mime: String}`. Ignore malformed rows. Skip
  paths that are empty or whose file does not exist.
- `Future<void> presentIfNeeded()`:
  1. `await pullFromNative()` (and, on iOS later, also `pullFromAppGroup()` if you add it).
  2. If `pending.isEmpty`, return.
  3. If current route is `AppRoutes.onboarding`, return **without clearing** pending.
  4. Compute `ids = suggestedToolIds(pending.map((e) => e.mime))`.
  5. If `ids.isEmpty`, clear pending and snackbar `'Can't open this file type'`.
  6. If `ids.length == 1`, `_open(ids.first)`.
  7. Else `Get.bottomSheet` / modal (`share_target_sheet.dart`) listing those
     tools via `ToolCatalog.byId`. On tap, `_open(id)` and close sheet.
- `_open(String toolId)`: keep pending until the destination tool calls
  `takeFor(toolId)`, then `openTool(tool)`.
- `List<SharedFile> takeFor(String toolId)`:
  - `pdf_merge` → take items where `shareKind(mime)==pdf`, remove them from pending
  - `image_compress` / `images_to_pdf` / `ai_ocr` → take image items, remove them
  - After take, drop leftover pending (do not leave orphans that reopen the sheet)

Register in `main.dart` next to other services:

```dart
Get.put(PendingShareService(), permanent: true);
```

After `bindLaunchHandlers()`, also:

```dart
unawaited(Get.find<PendingShareService>().presentIfNeeded());
```

Onboarding success path: after `Get.offAllNamed(AppRoutes.shell)`, call
`presentIfNeeded()` once.

Chooser UI: `ListTile` with tool icon + name + one-line description from
`ToolModel.description`. Use `Get.bottomSheet` with `theme.cardTheme.color`
and rounded top corners. Title: `Open with`. Cancel dismisses and **clears**
pending (user abandoned the share).

**Verify**: `flutter analyze` → 0. Tests still pass. You cannot fully test the
sheet without a device; router tests cover the decisions.

### Step 3: Preload in three tools

In each tool `initState`, after `super.initState()`:

```dart
final share = Get.isRegistered<PendingShareService>()
    ? Get.find<PendingShareService>()
    : null;
final files = share?.takeFor(<this tool id>) ?? const <SharedFile>[];
if (files.isNotEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    // add to existing lists / set _original
  });
}
```

- **pdf_merge**: for each file, `PlatformFile(name: basename, path: path, size: File(path).lengthSync())`. Skip if `path` null/missing. Do not start merge automatically.
- **image_compress**: use the **first** image only as `_original`, then call existing `_compress()` if that is what a gallery pick would do. If `_compress` requires user gesture, set state and let the existing slider/button work — match current pick behavior.
- **images_to_pdf**: ` _images.addAll(files.map((f) => XFile(f.path)))`. Do not auto-create the PDF.

Do not change pickers. User can still add more files.

**Verify**: `flutter analyze` → 0. Read each `initState` and confirm `takeFor` is called once.

### Step 4: Android receive

**Manifest** — add **after** the existing VIEW filter, still inside the
`MainActivity` `<activity>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.SEND"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <data android:mimeType="application/pdf"/>
    <data android:mimeType="image/*"/>
</intent-filter>
<intent-filter>
    <action android:name="android.intent.action.SEND_MULTIPLE"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <data android:mimeType="application/pdf"/>
    <data android:mimeType="image/*"/>
</intent-filter>
```

Do **not** add `ACTION_VIEW` for pdf/image. Do **not** add storage permissions.

**MainActivity.kt** — implement, keep package `com.kamranibrahim.onetoolkit`:

- Channel `com.kamranibrahim.onetoolkit/share`
- In-memory `ArrayList<HashMap<String, String>> pending`
- `configureFlutterEngine`: register `MethodChannel`; `takePending` returns the
  list and clears it.
- `onCreate` / `onNewIntent`: `setIntent(intent)` then `ingest(intent)`
- `ingest`:
  - `ACTION_SEND` → one `Intent.EXTRA_STREAM` Uri
  - `ACTION_SEND_MULTIPLE` → `ArrayList<Uri>` extra
  - For each Uri: copy `contentResolver.openInputStream` to
    `File(cacheDir, "share_${timestamp}_${safeName}")`. `safeName` from
    `OpenableColumns.DISPLAY_NAME` or `uri.lastPathSegment` or `file.bin`.
    Strip path separators from the name.
  - MIME from `intent.type` or `contentResolver.getType(uri)` or
    `application/octet-stream`
  - Skip failed copies (do not crash)
- After ingest, if Flutter engine already up, you may invoke
  `channel.invokeMethod("onShared", null)` so Dart re-pulls. Dart must also
  pull on resume (`WidgetsBindingObserver` on `PendingShareService` or a tiny
  observer in `OneToolkitApp` / shell). Implement **one** of: native invoke
  `onShared` **or** Dart `didChangeAppLifecycleState == resumed` →
  `presentIfNeeded()`. Prefer both (idempotent if pending empty).

**Verify**: `flutter analyze` → 0. If the Android SDK is available:
`flutter build apk --debug` → exit 0. If that build is not possible in this
environment, say so in the status note and rely on analyze.

Manual check (do not skip documenting it in the PR/commit body): from Files or
Photos, Share → OneToolkit → Merge PDF / Compress Image with the file already listed.

### Step 5: iOS Share Extension

Only after Steps 1–4 compile.

Follow `ios/scripts/add_favorites_widget.rb` to write
`ios/scripts/add_share_extension.rb` that adds target `ShareExtension`,
bundle id `com.kamranibrahim.onetoolkit.ShareExtension`,
App Group `group.com.kamranibrahim.onetoolkit`, iOS 17, embed in Runner.

Extension Swift (keep it small):

1. Accept `NSExtensionActivationSupportsFileWithMaxCount` ≥ 10 and image/pdf types
   via `NSExtensionActivationRule` in `Info.plist` (UTType PDF + images).
2. Copy provider file URLs into
   `FileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kamranibrahim.onetoolkit")!/Inbox/`
3. Write `Inbox/manifest.json` as `[{"name":"...","mime":"..."}]`
4. Open the host app: `onetoolkit://share` via `extensionContext.open` or
   responder `openURL` (iOS version differences — try `open` on the context first).
5. `completeRequest`

Dart `pullFromNative` on iOS: add a second channel method `takeInbox` implemented
in `AppDelegate` / `SceneDelegate` that reads `Inbox/`, returns
`[{path, mime}]`, then **deletes** those files so the next share is clean.

Handle `onetoolkit://share` in Swift `application(_:open:)` **or**
`scene(_:openURLContexts:)` (this project uses `SceneDelegate` —
prefer the scene method). On that URL, invoke Dart `onShared`.

Also extend `WidgetSyncService._openFromUri` **or** the new service: if
`uri.host == 'share'`, call `presentIfNeeded()` instead of treating `share`
as a tool id. Today `_openFromUri` requires `host == 'tool'`, so `share` is
already ignored — do not accidentally pass `share` to `ToolCatalog.byId`.

**If the ruby script or Xcode target fails to produce a buildable iOS app
after one fix attempt**: leave `ios/ShareExtension/` sources on disk, do not
half-edit `project.pbxproj`, set plan 003 status to
`DONE` with note `iOS extension BLOCKED: <reason>` in `plans/README.md`.
Android + Dart still count as the required delivery.

**Verify iOS** (when target exists): `cd ios && xcodebuild -list` shows
`ShareExtension`. Do not require a device run if signing is missing (paid
Apple account / App Groups). Document Settings → Signing like
`ios/FavoritesWidget/README.md`.

## Test plan

- New: `test/share_router_test.dart` (Step 1 cases).
- Pattern: `test/widget_test.dart`.
- No integration_test device farm in this plan.
- Manual: Android share one PDF, two PDFs, one photo, two photos, cancel sheet.

## Done criteria

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0 including `test/share_router_test.dart`
- [ ] Manifest has SEND + SEND_MULTIPLE for `application/pdf` and `image/*` only
- [ ] Manifest still has **no** `ACTION_VIEW` for pdf/image and **no** new `READ_MEDIA_*`
- [ ] `MainActivity` copies `content://` streams to cache before handing paths to Dart
- [ ] `pdf_merge` / `image_compress` / `images_to_pdf` preload via `takeFor`
- [ ] Onboarding does not drop a cold-start share (pending survives until shell)
- [ ] No new pubspec dependencies
- [ ] `rg "receive_sharing_intent" pubspec.yaml` → no matches
- [ ] No files outside the in-scope list
- [ ] `plans/README.md` row updated (`DONE` or `DONE` + iOS blocked note)

## STOP conditions

- Manifest already has `ACTION_SEND` (someone started this).
- You believe you must add `READ_MEDIA_IMAGES` or `MANAGE_EXTERNAL_STORAGE`.
  Wrong — use the grant on the shared Uri only.
- You are about to add `ACTION_VIEW` for `application/pdf`.
- Tool screens require rewriting `openTool` arguments to a Map. Use
  `PendingShareService.takeFor` instead.
- Adding a pub.dev “receive share” plugin looks easier. Do not.
- iOS: after one failed `xcodeproj` script attempt, follow the fallback in Step 5
  — do not hand-mangle `project.pbxproj` for pages.
- A Dart/Android verification fails twice.

## Maintenance notes

- Adding Compress PDF or OCR preload later is a one-line change in
  `suggestedToolIds` plus `takeFor` + `initState` in that view.
- Reviewer: confirm Play-safe permissions; confirm mixed shares do not send a
  photo into `PdfCombiner.mergeMultiplePDFs`.
- Deferred: iOS if blocked; text shares; `ACTION_VIEW`; resume of previous
  merge file lists (plan 002 Continue is launch-only).
