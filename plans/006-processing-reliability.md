# 006 — Processing and output reliability

Status: IMPLEMENTED — device acceptance pending · 15 October 2026

Scope: reusable CSV codec, filename/rename validation, file-backed ZIP creation/extraction, PDF output verification and compression; wire the four screens to those operations. Preserve unrelated work and dependencies.

Contracts:
- CSV preserves quoted records, escapes and whitespace; rejects malformed/ambiguous inputs instead of dropping fields or JSON rows.
- Rename previews and export share one naming function. Reject unsafe names and case-insensitive collisions before copying. Original files are read-only.
- ZIP retains folder structure, rejects unsafe/conflicting paths and symlinks, verifies sizes/CRC, bounds input/count/expanded size, and removes partial outputs on failure. Processing runs outside the UI isolate.
- PDF compression defaults to preserving text, layout and forms, verifies outputs, and returns the original when no smaller valid result is available. Existing scanned-image compression remains an explicit lossy option with page geometry preserved. Reject signatures before rewriting. Exports cannot reuse stale results while settings or processing change.
- Guard disposed-screen updates and surface failures. Leaving a screen prevents automatic sharing; long operations finish within bounds and clean temporary intermediates. Interruptible/resumable jobs remain plan 007.

Validation: real CSV round trips and malformed fixtures; filesystem ZIP/rename fixtures including collisions, traversal, expansion limits and corrupt data; generated PDF fixtures for text, mixed geometry, forms and size outcomes; full tests and analyzer; Android compile. Physical-device raster-quality/performance and supported-iOS checks remain explicit limitations.

Rollback: revert batch code; no schema or dependency migrations. Generated results remain ordinary temporary exports.

## Implemented behavior

Shared operations now live under `lib/data/processing/` and take explicit inputs, rather than depending on screen state or navigation. The four tool screens use those operations.

- CSV: full record parsing including CR/LF inside quotes, escaped quotes, significant whitespace, BOM and trailing empty cells. Headers must be unique/non-empty and row widths must match. Mixed JSON arrays and nested structures fail explicitly. Header names are escaped when exporting CSV. CSV is text-valued; JSON null/missing cells become empty strings, disclosed in the screen. Conversion is bounded to two million characters and runs in a worker isolate. New runs clear old results and controls are disabled during processing.
- Rename: preview/export use one template contract. Preserve source extensions, replace tokens once, reject malformed/empty patterns, reserved names, path components and case-insensitive collisions before writing. Rename export streams the original files into ZIP entries with the new names; no unnecessary intermediate copies.
- ZIP: file-backed reading, streamed inflate with actual-byte limits and CRC verification, preserved nested paths, preflight entry/name checks, collision/traversal/symlink rejection, and cleanup after failures. Directory parsing is bounded before constructing entries; ZIP64/multi-volume/encrypted/unsupported-compression archives fail clearly. New archive generation also enforces the output-size limit so it cannot create an archive this tool cannot reopen. Work runs in a worker isolate.
- Extraction UI: results remain available to share individually; bulk sharing is offered only when basenames are unique, because share destinations may flatten folders. The full extracted directory structure remains in the app's temporary working directory. Sharing individual files does not promise to transmit their parent folders.
- PDF: preservation-oriented re-save is now default; a smaller candidate must reopen with matching text, page geometry/rotation, form count and annotation counts. Signature fields are rejected before rewriting. Candidate copies that are not smaller are deleted and the original is returned with an honest status. Original files are never rewritten.
- Scanned PDF: remains an explicit lossy choice with a visible explanation. It uses each original page's dimensions and explicit portrait/landscape orientation when rebuilding, fixing the landscape geometry issue found by fixtures. It is limited to 20 unrotated pages without forms and ordinary page dimensions. Native page rendering/compression still needs physical-device quality checks.
- Screen lifecycle: the changed async paths check mounted state before UI updates and suppress automatic sharing after navigation away. PDF results are invalidated when settings change or processing restarts; sharing failures are surfaced.

## Supported bounds

- CSV/JSON input: 2,000,000 characters.
- ZIP input/output: 100 MiB; at most 1,000 entries; at most 256 MiB expanded total and 128 MiB per entry; central directory at most 4 MiB. These are initial product limits, not performance benchmark results.
- PDF: 50 MiB input and 1–100 pages; scanned-copy path additionally at most 20 pages, no rotated pages/forms, maximum page dimension 2,000 points.

## Verification and remaining scope

Final command results are recorded below. Regression coverage includes real CSV round trips, malformed inputs, byte-for-byte archive content, nested names, exact/case-only duplicate names, corrupted CRC/size metadata, output limits, preservation of originals, generated PDFs with text/forms/mixed geometry, signature-field rejection and raster assembly dimensions.

This batch does not provide a target-byte-size solver, guarantee that preservation mode can shrink an already compressed file, certify all PDF interactive features, or prove raster visual fidelity on devices. Preservation checks compare extracted text and structural counts; they are not a full visual/semantic equivalence proof. Some fixtures legitimately return the original because a re-save gives no size reduction.

Leaving a screen does not terminate a worker; bounded work completes and temporary results follow existing cache behavior. Explicit cancellation, expiry, durable saved artifacts and resumable jobs remain plan 007. HTML/SQL formatter semantics, streaming checksum/duplicate tools, CI setup and broader device-performance work remain separate follow-ups. No dependencies, permissions, storage schemas or platform release settings changed in this batch.

## Final results — 15 October 2026

- `flutter test`: **84 passed** (36 existing, 48 new processing regressions).
- `flutter analyze`: **eight pre-existing informational lint findings**, no analyzer errors/warnings and no new findings. One previous redundant import disappeared with the PDF screen refactor; remaining unrelated findings were preserved. Exit 1 reflects those informational findings.
- `flutter build apk --debug`: **passed** on the final application changes.
- iOS simulator compilation: **passed** using the same temporary invocation overrides documented in 005 (arm64, no signing, deployment target 17). A concurrent existing iOS run temporarily held Xcode's build database; compilation succeeded after that run released it. This is not a signed release or a test on older supported devices.
- `git diff --check`: **passed**.
- Physical-device raster fidelity, large-file performance, signing/store acceptance: **pending**.

An external Flutter run was active during checks. Additional iOS project/Info.plist metadata edits appeared while it was active and were preserved, rather than reset. The processing implementation intentionally changes no platform permissions or release settings. Pre-existing dependency/build changes and the prior share-reliability work remain intact.
