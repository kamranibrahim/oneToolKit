# 009 — Guided submission and document checklists

Status: implemented; automated checks complete; physical-device acceptance pending.

## Outcome

New saved tasks offer three optional starting guides: Scanned document (images to PDF), Combined PDF (merge PDFs), and Application ZIP (package selected documents). Each sets an editable task name, operation, output name and suggested document labels. Selecting a guide replaces the draft settings and file selection; the form explains this. Guides do not prescribe destination-specific size/page limits or claim an official document list. Existing manual task creation and routines remain available.

A task can hold up to 30 named document checklist items. Before creating the task, users can add, edit or remove labels. After importing files, users link each item to one or more original or processed saved files, then explicitly acknowledge reviewing the linked document. Each item distinguishes missing files, linked-but-unreviewed files, and reviewed-by-you files. Changes to a label or file links clear the acknowledgement. Checklist editing is unavailable during processing or another save.

Completed tasks include checklist items in “Check submission requirements,” alongside measured export rules. Missing or unreviewed items remain unresolved. Linked files are verified against their saved hashes on every check, including originals that are separate from the final export. A review acknowledgement means the user reviewed the linked saved document; it does not certify content, completeness, authenticity, acceptance or the final archive's internal structure. Users still inspect the export and destination instructions.

Saving a routine keeps checklist labels only. File associations and review acknowledgements never carry into a new run. A routine survives deletion of its original task; Clear local data deletes both tasks and routines while preserving chosen source files.

## Persistence

Job schema 3 adds checklist entries; schemas 1 and 2 migrate with an empty checklist. Routine schema 2 adds labels; schema 1 migrates with an empty checklist. Future versions retain existing fail-safe handling: preserve files and surface warnings. Checklist entries validate UUIDs, label length, unique IDs, bounded item/file counts and references to known saved artifacts. Saves use the existing atomic checkpoint/revision mechanism. Starting a task is blocked during a save to avoid checkpoint races.

## Verification

- 133 automated tests pass (11 added plus expanded guided picker-to-export coverage).
- Tests cover durable missing/linked/reviewed states, review reset on edit/relink, invalid and unknown references, tamper detection, clean routine reuse, older schema compatibility, processing/relaunch retention, clear-data semantics, concurrency guards and checklist UI interactions.
- Static analysis: no errors/warnings; eight existing informational findings remain.
- Android debug build succeeds.
- iOS simulator build succeeds with temporary arm64, iOS 17 and no-signing overrides. Existing release configuration remains unchanged.

## Device acceptance

1. On both platforms, select each guide and confirm operation, filenames, ordering and suggested labels. Edit labels and add/remove items. Review instructions and enter real export limits manually.
2. Import and process files. Link original and processed files, preview their contents, mark reviewed and reopen the task after relaunch.
3. Change a link or label: review must reset. Leave another item missing: combined submission check must remain unresolved.
4. Save a routine, delete its original task and run with fresh files: labels must remain but links/review must be empty.
5. Check scrolling with large text, keyboard and narrow screens; inspect the final export and sharing on a real device.

## Next

Prototype an optional instructions-to-rules assistant: paste destination instructions, propose a checklist and measurable rules, show source text for every proposal, and require user review before applying. Decide local/cloud execution, privacy and cost before connecting an external AI provider. Keep the deterministic file pipeline and measured checks authoritative.
