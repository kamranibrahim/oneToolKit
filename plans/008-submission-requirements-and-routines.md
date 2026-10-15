# 008 — Submission requirements and reusable routines

Status: implemented; automated checks complete, physical-device acceptance pending.

## User outcome

Saved work can now carry user-entered limits for the final export: maximum bytes, maximum PDF pages, PDF/ZIP file signature and an exact filename including extension. All fields are optional. Processing completion and submission readiness remain separate.

On a completed task, “Check submission requirements” verifies stored file integrity and reads the export afresh. Each rule reports passed, failed or unresolved. Checks run in a worker isolate. Reports are deliberately ephemeral: reopening or changing a file cannot leave a stale persisted success. The app does not look up a destination's rules or promise acceptance. Users still review readability, content and current destination instructions. A ZIP cannot satisfy a PDF page rule; that rule remains unresolved.

“Save settings as a routine” stores the task's title, ordered operation settings, output names and requirements. It stores no input paths or file contents. Routines appear in Saved work and require fresh file selection. Routine operation settings remain fixed while task title and requirements can be adjusted for the new run. Delete a routine independently of its originating task. Clear local data removes both.

## Persistence and bounds

- Job schema 2 writes requirements; schema 1 opens with no rules. Unknown versions remain untouched.
- Routine schema 1, UUID filenames under the existing private, backup-excluded saved-work root; atomic write/rename, serial repository mutations, maximum 50 routines and 16 KiB per record, shared storage quota.
- Corrupt/future routine records are retained with a visible warning. Interrupted `.next` files are cleaned on opening routines. Routine directory symlinks are rejected.
- Limits: maximum bytes 1–500 MiB; page limit 1–100. Inspection refuses exports above the processing limit of 100 MiB. Exact names use existing safe filename validation.
- Format validation checks file signatures; it is not a full structural certification. PDF page counting additionally parses the PDF and reports unresolved if unreadable. ZIP contents, legibility, required documents, signatures, identity and authenticity are outside these measured checks.

## Validation

122 automated tests pass, including 11 new tests for exact boundaries, all four unmet rules, disguised and unreadable PDFs, ZIP/page ambiguity, invalid rules, schema migration, durable routines with fresh inputs, corrupt/future records, clearing data, integrity failure and UI prefilling without reusing files.

Static analysis has no errors or warnings; eight pre-existing informational findings remain. Android debug build succeeds. iOS simulator compilation succeeds using temporary iOS 17 / arm64 / no-signing overrides, as in batch 007; release compatibility settings are unchanged.

## Device acceptance before release

1. Create an images-to-PDF task with filename, size, format and page rules. Inspect PDF and run checks. Repeat with deliberately failing limits.
2. Package PDF as ZIP and confirm page-count rule is unresolved.
3. Save a routine, delete its original task, relaunch and run with different files. Verify operation/output settings and requirements match.
4. Delete a routine and clear local data; verify source files remain intact.
5. Check small-screen form/dialog scrolling, large-text layout, both platforms' pickers and sharing.

## Next product step

Build guided submission presets and editable document checklists around real user needs. Then prototype an optional AI helper that converts pasted instructions into proposed, user-reviewable rules. Keep deterministic validation as the authority for measurable constraints; decide AI privacy, provider and costs before implementation.
