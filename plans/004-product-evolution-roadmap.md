# OneToolkit: project assessment and next roadmap

Reviewed: 15 October 2026.
Status: IN PROGRESS. Share reliability implementation is recorded in plan 005; physical-device acceptance and subsequent phases remain.

## Decision

Evolve OneToolkit into a private workspace that understands selected files and helps people finish document and image tasks. Keep the existing tools as useful standalone entry points and progressively reuse their processing through a shared execution layer.

First flagship: **Prepare documents for submission.** A person brings photos/PDFs and requirements, reviews the proposed steps, fixes missing items, and exports a verified package. Add AI to interpret requirements and map files to a checklist; use deterministic operations to create and validate outputs. Expand into receipts, recurring client work and image preparation after the first workflow demonstrates repeat use.

This is a recommended starting hypothesis based on the code's strengths, not a finding about current customers. Confirm it with current users before committing to a broad rebuild.

## Review scope and limitations

Reviewed project inventory, catalog and routing, application startup and navigation, shared services and history, existing implementation plans, native sharing/widgets configuration, representative processing implementations across the tool families, and test coverage. Examined PDF compression/protection/page helpers; image compression/conversion/metadata/cutout; OCR/translation/summarization; ZIP/rename/duplicates; CSV/formatters/diff; scanner, settings and persistence.

Verification run against this working checkout:

- `flutter test`: **23 tests passed**, four Dart test files.
- `flutter analyze`: **exit 1, nine informational lint findings**: seven unnecessary imports and two private-type API lint findings in a test file. No analyzer errors or warnings reported.
- 130 Dart files under `lib`, approximately 17,795 lines; 85 catalog entries and 87 tool-related Dart files, including helpers.
- No `.github` directory or Dart integration-test directory found in this checkout.

This is a repository assessment, not a runtime certification of every tool. No new Android/iOS builds, physical-device tests, store-console checks, accessibility audit, user interviews, financial forecast or model benchmark were performed. Store availability comes from the owner. Existing uncommitted changes to dependency/build files and existing untracked plans/assets were preserved.

## Current capability assessment

| Area | Built today | Implication |
|---|---|---|
| Catalog | 13 PDF, 10 image, 8 document, 6 QR, 16 text, 25 developer/utility, 4 file, 3 AI tools | Broad execution foundation; breadth alone does not establish depth or output quality |
| Discovery | Keyword/alias search, categories, favorites, pins, recent tools and usage ranking | Retain while adding task-oriented entry points |
| Platform entry | Android/iOS PDF/image share-in, outbound sharing, native favorites widgets and tool deep links | Good starting distribution surface; end-to-end correctness still needs device checks |
| Persistence | GetStorage for preferences, notes, searches and up to 100 action records | Suitable for small preferences; no durable workspace/job/artifact model |
| AI | Latin-script image OCR, 16 exposed translation choices with downloaded models, frequency-ranked extractive summaries | Useful local capabilities; no generative planner, document understanding or retrieval layer |
| Execution | Primarily processing inside StatefulWidget screen classes | Operations cannot readily be chained or resumed outside their screens |
| History | Tool/action/time/detail, with taps reopening a tool | Not restoration of an unfinished job or reopening of its output |
| Product operations | No connected usage/crash service or billing layer found in app dependencies/services reviewed | No evidence here for retention, demand or willingness to pay; preserve privacy when introducing measurement |
| Localization | English strings, no supportedLocales/localization setup found | Regional expansion requires UI localization and separate OCR/model language validation |

The three previous plans are marked DONE. Live code contains their ranking, pins/widgets and share-in work. This does not imply that their entire device acceptance checklist has passed; share-in has concrete gaps below.

## Findings to address before layering automation

### 1. Shared image to OCR loses the input — confirmed code path

`lib/data/services/pending_share_service.dart`, `_open`, calls `takeFor('ai_ocr')` and discards its returned files. `lib/modules/tools/ai/ocr_view.dart` has no shared-file preload; `_run` always opens camera/gallery.

Fix: pass a typed input to OCR or let its controller consume the pending input exactly once. Test the actual handoff, not just suggested tool IDs. Device check: share image → OCR → recognized text without picking the image again.

### 2. Share selection can discard unprocessed files — confirmed code path

`takeFor` filters by selected tool then clears the entire pending collection. Mixed PDF/image batches therefore lose the other input kind from pending state. Multiple images can be offered to image compression, but that screen uses only `files.first`.

Fix: preserve a batch and mark individual inputs consumed; explicitly show single-file versus batch behavior. Unused inputs must remain available or be explicitly dismissed by the user.

### 3. PDF compression is a destructive representation change

`lib/modules/tools/pdf/pdf_compress_view.dart` renders pages as JPEGs and rebuilds the document. It does not preserve original text/vector representation, has no requested-byte-size solver, and reports completion without checking that the result is actually smaller. The screen does disclose that it is best for scanned documents.

Fix: distinguish scanned from text PDFs, offer a preservation-oriented path where supported, show quality tradeoffs, verify output bytes and page geometry, and avoid claiming a limit is met unless measured. Retain originals. Test selectable text, mixed page sizes and landscape pages before automating this operation.

### 4. Jobs and outputs are not durable

HistoryItem stores no input/output references or operation settings. Home Continue and history reopen tool screens. Many exports are temporary files, and Clear local data removes preference/history/note records without managing these generated files. There is no central artifact retention service in the reviewed services.

Fix: add stable artifact IDs, durable storage for explicitly retained work, job checkpoints and deletion/expiry rules. Show temporary versus saved results accurately. Recover from missing files without startup failure.

### 5. Large work can block interaction or exhaust memory

Image compression decodes and encodes synchronously on the Flutter execution path; duplicates/checksums read full files; ZIP extraction loads/decompresses an archive in memory. Android share ingestion copies streams directly during activity callbacks. Several async tool paths call setState after awaits without consistently checking mounted.

Fix: offload eligible CPU processing, stream file hashing, bound inputs and expanded archive size/count, move native copies off the UI thread, and define cancel/exit handling. Benchmark on a representative lower-memory phone; do not infer acceptable performance from desktop tests.

### 6. Some data tools can change or lose content

CSV parser splits records on newlines before parsing quotes and does not preserve escaped double quotes; JSON-to-CSV does not escape header names. HTML/SQL formatters normalize whitespace without respecting all literal contexts. Diff compares line positions, so one insertion can produce a cascade of apparent changes.

ZIP extraction flattens directory paths with basename, allowing files in different folders with the same name to overwrite one another. Batch rename does not validate output names or detect collisions before copying.

Fix: add real-world fixtures and parser-backed behavior where appropriate; preserve strings and quoted records; validate destination containment and filename uniqueness; choose a visible collision policy. These tools should not enter autonomous workflows until their contracts are tested.

### 7. Offline and privacy states need precision

ToolScaffold always displays OfflineBadge; translation and Android background removal can require first-use downloads. GetStorage is used without application-level encryption configuration in the reviewed service. Local processing is valuable, but it does not by itself establish encrypted storage or backup behavior.

Fix: model ready-offline / download-required / network-optional / unavailable states per capability. Define sensitive workspace storage, device backup policy, model management and delete-all behavior before persisting documents or adding cloud AI. Never persist document passwords as routine settings.

### 8. Platform inbox needs robust batch semantics

iOS extension filenames use second-resolution timestamps plus original names and remove existing destinations. Same-name inputs within a second can collide. Host inbox processing removes the whole inbox after attempting copies, even if individual copies fail. Android silently skips failed copies.

Fix: unique batch/file IDs, atomic manifests, copy acknowledgments, retryable failures and explicit user feedback. Preserve input ordering. Validate cold start, warm start, onboarding, cancellation, consecutive shares and app termination on both platforms.

### 9. Tests cannot currently establish document reliability

The four Dart test files cover catalog lookup, shortcut order, ranking and MIME suggestions. `widget_test.dart` contains catalog unit tests rather than rendered-widget tests. Native RunnerTests is not evidence of a document regression suite.

Fix: add meaningful output tests for the shared operations plus integration/device coverage for the flagship path. Automate analyzer and tests in CI; add platform compile checks and a release smoke checklist. Resolve the nine current lint findings. Align versioning: Android currently hardcodes versionCode 4/versionName 1.0.0 while pubspec declares 1.0.0+1. Make release signing fail explicitly when required credentials are absent instead of silently selecting debug signing.

## Target architecture: evolve one vertical slice

Keep Flutter, current routes and GetX. No full rewrite or migration of all 85 tools is needed.

1. **Artifact repository:** stable IDs, source name/type, managed location, size/hash, lifecycle, optional workspace relation and derived-output lineage. Store imported content only through explicit user selection. Pick the structured persistence implementation after testing transactions, schema migration and file lifecycle together; keep GetStorage for preferences.
2. **Operation layer:** typed inputs/options/results, supported types, capability requirements, validation, progress and cancellation boundaries. Extract merge, images-to-PDF, resize/compression and OCR first. Avoid dependencies on BuildContext/Get navigation in processing code.
3. **Job runner:** ordered operation steps, durable state, validated input/output references, retry rules and foreground recovery. Checkpoint only at safe boundaries. Mobile process termination must not be treated as guaranteed continuous background execution.
4. **Understanding layer:** PDF native-text extraction before OCR fallback, page/block source references and document classification. Preserve original text and user corrections. Language/script support must be explicit; Latin OCR does not imply Urdu/Arabic OCR support.
5. **Planner:** converts a supported request to a validated, allowlisted task plan. Missing constraints become questions; unsupported requests stay unsupported. It never generates executable code or arbitrary file commands. File contents are data, not execution instructions.
6. **Validation and review:** deterministic checks for bytes, page count, format and filenames; source-linked review for extracted facts. Separate measurable acceptance from subjective readability and user confirmation.

Proposed modules: `lib/domain/artifacts`, `lib/domain/operations`, `lib/domain/jobs`, `lib/data/repositories`, `lib/data/processing`, `lib/modules/workspaces`, `lib/modules/tasks`. Names are provisional; implementation should follow the final vertical slice.

Proposed records:

- Artifact: id, workspaceId, managedLocation, displayName, mime, bytes, hash, createdAt, retention, derivedFrom.
- Job: id, schemaVersion, status, inputIds, steps, currentStep, outputIds, validations, error, timestamps.
- Step: operationId, operationVersion, typed options, inputIds, outputIds, status; secrets are ephemeral.
- Routine: id, supported input contract, parameterized step template and user-approved defaults.
- Extraction: artifactId, page/block coordinates, field/text value, extraction method and user-review state.

## Delivery sequence and acceptance gates

Effort ranges below are provisional focused engineering estimates for one experienced Flutter developer with native testing access. They exclude store review time and depend on document-engine/model feasibility. Re-estimate after Phase 1; they are not delivery promises.

| Phase | Indicative effort | Deliverable | Acceptance gate |
|---|---|---|---|
| 0. Reliability baseline | 1–2 weeks | Share fixes, output correctness fixtures, filename/collision handling, lifecycle fixes, CI and release checks | Shared inputs survive; core fixtures pass; analyzer clean; Android/iOS flagship smoke checks recorded |
| 1. Execution foundation | 2–3 weeks | Artifact repository, job runner and first extracted operations; local saved work | Relaunch after interruption restores a valid job; cancelled/retried work does not overwrite originals or duplicate outputs; migrations and expiry tested |
| 2. Flagship beta | 2–3 weeks | Prepare for submission: mixed import, requirements form, checklist, page order, naming, size validation, preview/export and saved routine | Defined fixture packages satisfy measurable requirements or explain inability; users finish without reopening standalone tools |
| 3. AI within the flagship | 2–4 weeks | Requirement text/screenshot → proposed checklist; selected files → suggested mapping; limited natural-language plan | Source-linked extracted requirements, reviewed uncertain fields, schema validation, no unsupported actions; benchmark quality/latency/cost before expanding |
| 4. Repeat work | 2–4 weeks | Choose receipts-to-CSV OR recurring client packages based on beta evidence | Source-linked review, useful batch handling and measurable repeat completion; no simultaneous launch of multiple new audiences |
| 5. Expansion | After evidence | Additional task families, localization, optional sync, advanced image preparation | Existing flagship remains reliable; a new workflow has demonstrated demand and an acceptable support/cost profile |

Start user discovery alongside Phase 0: observe 10–15 existing users attempting recent tasks, review available store feedback and aggregate store statistics, and compare paperwork against image/client/receipt demand. No accounts or document uploads are needed for these interviews. Revise the flagship if evidence points elsewhere.

Phase 2 and Phase 3 together are the first major product milestone. The foundation should remain bounded to that milestone, rather than becoming months of infrastructure work without a usable experience.

## First flagship specification

User story: “I have documents and photos plus upload requirements. Help me make the right package and show what still needs work.”

Input: PDFs/images and user-entered requirements; add requirement screenshots/text interpretation in Phase 3. First supported constraints: accepted type, file count, per-file/total byte limits, page order/count and naming. Required-document names are reviewed checklist items, not proof of official eligibility.

Flow: import → inspect → review checklist/plan → arrange pages/files → process → validate → compare preview → save/export → optionally save routine.

Example: combine selected certificate images and a PDF into an ordered PDF under a user-supplied limit. If the quality floor prevents reaching that limit, return a clear unresolved requirement and alternatives. Do not silently reduce quality until technically under the limit. Where measurement is objective, show the measured result. Where judgment is required, request review.

Retain Tools, Favorites and existing entry points during rollout. Add a task entry to Home and a compact Saved Work destination once persistence exists. Revisit the entire navigation after observing beta behavior; a visual redesign alone does not resolve the processing gaps.

## AI feasibility and privacy decisions

Evaluate local and explicitly opt-in cloud approaches on the same held-out documents/requests. Measure extraction accuracy by field, unsupported-request handling, completion rate, model readiness, memory, latency, download size and variable cost. Include smaller Android devices and older supported iPhones. Do not select a provider/model based on this document.

If cloud AI is needed, add a minimal backend for credentials, quotas, request limits and abuse controls; do not ship a service secret in the app. Show precisely which selected content is sent and the applicable retention behavior. Prefer local inspection and deterministic execution regardless of planning method. A cloud option must not silently change the existing offline experience.

Any source-grounded answer must retain its page/block reference. Automated classification is a suggestion, not verification of authenticity or official acceptance. Permanent redaction is a separate later capability requiring tests that removed data is not recoverable from text, images, metadata and incremental PDF content.

## Evaluation and business gates

Primary product measure: successfully completed useful tasks per returning user. Current history cannot reliably measure this: some actions log at generation, some after opening the share sheet, and reopening a screen does not establish successful export.

Instrument locally first: task started, processing completed, validation passed/failed, export attempted/completed/cancelled where observable, recovery and errors. Never count opening a share sheet as delivery to its recipient. Offer explicit opt-in aggregate diagnostics if needed; exclude names, file paths, document text and images.

Proposed beta targets, to be revised after observing a baseline:

- At least 90% of defined supported fixture tasks finish with validated outputs; track failure types separately.
- At least 95% of modeled interruption/retry cases recover without data loss; no known original-file overwrite cases.
- At least 30% lower median completion time than the same task through existing standalone tools, measured with users.
- Evaluate repeat completion over 2–4 weeks for genuinely recurring jobs; do not require weekly use for an inherently occasional application task.
- For AI fields, report precision/recall or exact-match accuracy on a held-out corpus, plus correction rate; do not rely on model-reported confidence.
- Record cloud cost per completed task and support burden before deciding pricing or quotas.

These are proposed internal gates, not measured app performance or market benchmarks.

Current settings say “Free forever” and current store copy says the app is free. Preserve existing access expectations. Any future paid recurring/batch/cloud feature requires a deliberate product decision, clearly separated entitlements and accurate product/store wording. Do not add subscriptions before validating repeated value and operating costs.

## Next implementation batch

Create separate, reviewable implementation plans in this order:

1. **005 — Share batch correctness:** OCR handoff, retained mixed batches, explicit batch support, native unique identifiers/copy acknowledgment, regression/device tests.
2. **006 — Processing and output reliability:** compression contract, CSV fidelity, archive/rename collisions, mounted/cancel behavior and bounded large-file processing; prioritize operations entering the flagship.
3. **007 — Saved artifacts and resumable jobs:** schema/migrations, retention/delete behavior, operation contracts and first four adapters.
4. **008 — Prepare-for-submission beta:** guided end-to-end workflow, constraints, preview, export and local evaluation events.
5. **009 — AI requirements assistant:** benchmark first, then constrained planner/extraction with source references and an explicit execution preview.

Each implementation plan should identify its exact files, migration needs, fixtures, platform checks and rollback/compatibility behavior before coding begins. Leave plans 001–003 as historical records; do not reinterpret their DONE labels as certification of the new architecture.

Recommended immediate action: execute the reliability work for share-in while validating the flagship with current users. The next major release should demonstrate one complete intelligent workflow and the infrastructure to grow it into many.
