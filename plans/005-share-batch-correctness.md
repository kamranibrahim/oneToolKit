# 005 — Share batch correctness

Status: IMPLEMENTED — device acceptance pending · 15 October 2026

Scope: PendingShareService, share routing/sheet, OCR preload, a shared pending-input banner in shell/tool screens, Android share copy/acknowledgment, iOS extension/host inbox handling, regression tests.

Contract: consume only supported inputs; single-image tools consume one; preserve remaining files in input order; cancelled chooser keeps files reachable; explicit discard clears the queue. Serialize intake/presentation and deduplicate repeated native delivery. Native files use unique identifiers. iOS publishes complete manifests atomically and retains sources until Dart acknowledges copied inputs. Android retains native pending rows until acknowledgment and copies off its UI thread.

Compatibility: no dependencies, permission changes or storage migration. Read legacy iOS inbox manifests during transition. This batch's Dart queue is session-local; durable artifacts/process-death recovery belong to plan 007. Originals remain external to queue cleanup.

Validation: meaningful Dart service/channel and UI tests, analyzer, Android debug compile, unsigned iOS compile if available. Record physical-device checks as pending unless actually executed. Review diffs for accidental dependency/build changes.

Device acceptance: cold/warm launch and onboarding; image to OCR without picker; mixed inputs retain unused files; multiple-image compression consumes only one and labels this; cancel/reopen/discard; consecutive same-name files; native copy failure; iOS inbox order/retry; exit OCR during recognition.

Rollback: revert this batch's code; already committed iOS batch directories require the new reader or manual recovery before rollback. Do not remove pending content as part of rollback.

## Implementation notes

- OCR consumes its shared image after the first frame and recognizes it without invoking the picker. All four receiving tool screens now consume after layout, avoiding reactive queue updates during navigation builds. OCR scrolls on short screens and ignores completed recognition after disposal.
- Shared inputs are consumed by MIME contract and tool capacity: merge/images-to-PDF accept matching batches, compression/OCR accept one image. The remaining queue is accessible from a Review banner in the shell and tool screens. Keeping/dismissing the chooser preserves inputs; discard is explicit.
- Chooser text reports how many files a tool will use and how many remain. Selected handoffs are limited to the offered snapshot, so a concurrent share does not silently expand the selected batch. Deliveries during the chooser are pulled afterward. Reopening the same tool from a new share is supported.
- Native delivery is acknowledged after Dart accepts existing local copies. Session-wide deduplication avoids replay after consumption/discard when acknowledgment retries. Missing files are not acknowledged.
- Android metadata/copy work runs serially off the activity thread, preserving attachment order. UUID filenames avoid collisions, MIME detection prefers individual URI metadata, failed partial copies are removed, and failed imports surface a message.
- iOS stages each UUID batch separately, writes an atomic ordered manifest, then publishes it. Host intake retains each source until acknowledgment, retries failed copies, keeps stable destination paths, and supports legacy flat manifests. The actual Foundation-only host reader is exercised by the native regression harness.

## Verification results

- `flutter test`: **36 tests passed** (23 existing + 13 new service/widget regressions).
- `python3 test/native/run_share_inbox_tests.py`: **all three scenario groups passed**: ordering/redelivery/acknowledgment; failed-copy retry; legacy/invalid/uncommitted inputs.
- `flutter analyze`: nine pre-existing informational findings, no analyzer errors/warnings and no new lint findings. Exit 1 reflects the informational baseline.
- Android debug compile: passed, including the final verification after native and receiving-screen changes.
- Standard unsigned iOS build: blocked by the existing iOS 13 deployment setting rejected by installed Xcode. A build override to iOS 15 exposed existing widget use of iOS 17 APIs; a generic simulator build also needed a single architecture for the Flutter framework.
- iOS simulator compilation **passed** using a temporary invocation override: `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0 build`. This does not certify current release settings or change minimum supported OS in the project.
- Physical-device checks, signing/App Group validation and store release: **not performed**. Device acceptance remains pending.

## Remaining limits

The accepted Dart queue remains session-local; after native acknowledgment it does not survive process death. Durable saved artifacts, quotas/expiry and resumable processing are planned separately. Discard removes queue entries, not externally selected originals; generated temporary copies follow existing platform cache behavior. Interrupted extension staging is not automatically reclaimed yet. No new dependencies, permissions or release settings were introduced; pre-existing dependency/build edits remain intact.
