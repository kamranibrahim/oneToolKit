# 010 — Local instructions-to-requirements prototype

Status: implemented; automated checks complete; physical-device acceptance pending.

## Outcome

New tasks and routine-based drafts have a “Read submission instructions” entry. Paste instructions, find suggestions, inspect each suggestion's exact source line and explanation, then explicitly select which to apply. No suggestion is selected automatically. Selected export rules replace their matching draft fields; selected document names are appended, deduplicated against existing checklist labels. Other draft values, selected files, task operations and output names stay unchanged. All resulting fields remain editable.

This is a deterministic local pattern reader, not an AI language model. It establishes the proposal/review/application flow without adding a cloud provider, credentials, charges or document uploads. The UI calls it a local helper, states that it recognises common English patterns and can miss requirements, and makes no AI claim. Pasted source text and analysis are held only in the review screen and are not stored with jobs/routines. Applied rules and checklist labels use the existing durable task model.

## Supported patterns

Examples:

- `Maximum file size: 2 MB`, `File size must not exceed 500 KB`, `Export size up to 1 MiB`.
- `Maximum pages: 4`, `Maximum PDF pages: 4`, `Document must have no more than 3 pages`.
- `Format: PDF`, `Required format: ZIP`, `Submit as PDF`, `PDF only`.
- `Required filename: application.pdf`, `Filename: "Application.ZIP"` (literal, safe PDF/ZIP filenames).
- A `Required documents:` or `Document checklist:` heading immediately followed by bullet/numbered document names.

Only one supported rule per line. Unrecognised text remains in a visible “Review manually” list. Conditional, optional, alternative and per-item wording is not converted into unconditional export rules. Unsupported filenames, numbers and units are retained for manual review. A pasted instruction cannot trigger file operations or external actions.

KB/MB use 1,000-based units, KiB/MiB use 1,024-based units. The explanation discloses this convention and asks users to confirm it matches their destination. Decimal limits convert using integer arithmetic, flooring fractional bytes. Page rules apply to final PDFs; a ZIP cannot satisfy the page-count check. Filename rules do not rename outputs automatically.

Different selected values for the same rule block application with an explanation. Duplicate identical rules are allowed. Editing source text discards the old analysis and selection; users must analyze again. Back/cancel applies nothing. Adding beyond the existing 30-item checklist limit applies nothing and shows an error.

## Bounds and privacy

- Maximum 12,000 pasted characters and 200 lines.
- At most 30 document suggestions; excess lines remain visible for manual review.
- Size/page/name constraints reuse current submission requirement limits.
- No network, new dependencies, API keys or persistence schema changes.
- Unsupported prose, other languages, personalised filename templates, ranges, conditional rules and mixed per-document limits need manual handling. This prototype does not claim complete extraction or destination acceptance.

## Verification

- 148 automated tests pass, including 15 new reader/review tests.
- Tests cover supported rules/source evidence, exact unit conversion, conditional/scope ambiguity, unsafe filenames, conflicts, unsupported instructions, document scoping/deduplication/bounds, extreme numeric input, stale analysis, selective application preserving a routine's existing fields, conflict feedback and leaving without applying.
- Static analysis: no errors or warnings; eight existing informational findings remain.
- Android debug build succeeds.
- iOS simulator build succeeds with temporary arm64/iOS 17/no-signing overrides. Release configuration remains unchanged.

## Device acceptance

1. Paste real destination instructions on both platforms. Check evidence, unrecognised lines, scrolling, keyboard and large text.
2. Apply a subset to a draft/routine; confirm unselected fields, files and task steps are unchanged. Adjust output naming/packaging to match the selected rules.
3. Edit pasted text after analysis, cancel, and select conflicting rules. Verify stale/cancelled/conflicting proposals are not applied.
4. Process a task, review documents and run measured submission checks. Reopen and reuse a routine; only approved settings/labels should persist.

## Next decision

Evaluate this flow with real instructions and users before connecting an AI model. A language-model extension should produce the same typed proposals with source evidence and uncertainty, keep explicit selection/application, and never replace deterministic file checks. Local/cloud model choice, privacy/consent, costs and backend credential storage remain separate implementation decisions. No provider integration is included in this batch.
