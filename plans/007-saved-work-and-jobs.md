# 007 — Saved work and resumable jobs

Status: IMPLEMENTED — device acceptance pending · 15 October 2026

Deliver one usable vertical slice: Saved Work accessible from Home, explicit imports into managed storage, persisted ordered jobs, verified retained results with preview/share/delete, and user-directed resume after interruptions.

Operations: PDF merge, images-to-PDF, preservation-mode PDF optimization, ZIP packaging. Allow a document operation followed by ZIP. Existing standalone tools remain available; this does not migrate all history into saved jobs.

Storage: no new dependency. Each bounded job has a schema-versioned JSON checkpoint, immutable file IDs/content hashes, and files beneath its own directory. Atomic checkpoint replacement, revision checks and serialized writes provide per-job commits. Import publishes a staging directory only after all inputs are copied. On startup, running jobs become paused; uncommitted scratch/output files are removed. Unknown/corrupt metadata is reported and preserved, never silently reset. Backward compatibility: no existing preferences/history schema changes; future checkpoint versions are read-only errors until supported.

Privacy: native storage location is excluded from automatic backup (Android noBackupFilesDir; iOS Application Support with isExcludedFromBackup). OS app-private storage, not a new app-level encrypted vault. User-selected imports only; no accounts/cloud. Files persist until explicitly deleted. Clear local data explicitly includes saved work; individual deletion/clear respect active jobs. Limits: 50 jobs, 500 MiB total managed disk usage, 100 MiB imported per job, 50 MiB per input, at most 100 inputs. Step outputs are bounded and hashed before commit. Durable original inputs are never rewritten.

Runner: allowlisted operation types, compatible MIME/input counts checked before execution, no secrets/options that execute code, single active run, checkpoint after each completed step, pause at safe step boundaries. Restarts resume from the last committed step; no promise of uninterrupted mobile background processing. Generated files must belong to the job's scratch area or an existing managed input. No implicit persistence from standalone tools in this batch.

Validation: filesystem tests for import, interrupted imports, schema/corruption, atomic/revision behavior, quota, integrity, deletion and orphan cleanup; controlled runner failures/interruption/retry/idempotence; actual PDF/image/ZIP adapters where possible; UI tests for saved-job access and actions. Full tests/analyzer, Android and compatible iOS simulator builds. Physical-device backup/protection, native merge and kill/relaunch remain explicit acceptance checks.

Rollback: existing app data untouched. Preserve the saved-work directory when rolling code back; old code will ignore it. Never delete durable work as part of rollback.

## Implemented

- Home → Saved work opens the task list. New task supports ordered imports, a task title/result filename, PDF merge, images-to-PDF, preservation-mode optimization or ZIP, and optional ZIP packaging after a document operation. Import order can be changed before saving.
- Details show step progress, retained intermediate/final results and original imports. PDFs/images can be previewed; files can be shared after hash/size checks. Pause stops at the next safe boundary. Interrupted jobs do not auto-run on startup. Delete requires confirmation; Clear local data now explicitly includes managed files/results.
- Checkpoints contain schemaVersion 1, operation version 1, revision, timestamps, status, next-step cursor, immutable artifact IDs, relative paths, sizes, SHA-256 hashes and lineage IDs. Unknown schema/operation versions are reported and preserved without cleanup or overwrite.
- Imports use `.import-<id>` directories and publish only after copying every file and flushing metadata. Each checkpoint uses write/flush/rename replacement. Revision checks prevent stale updates, stale cleanup and deleted-job resurrection. Saved paths survive relocation of the app data root.
- Successful step outputs are moved from the job's working area into immutable file directories before committing their IDs. Uncommitted outputs and work directories are removed on startup/retry. The committed input/output references survive failure; retry begins at the cursor. No external originals are rewritten or deleted.
- Native storage channel uses Android's noBackupFilesDir. iOS creates an Application Support directory with isExcludedFromBackup and completeUntilFirstUserAuthentication file protection. Storage initialization fails visibly if that private location cannot be prepared; it does not fall back to a backup-eligible folder.
- One runner owns the repository in the app process. Mutation serialization plus revision checks provide per-job transaction boundaries; this is not a multi-process database. No additional dependency or preferences/history migration was introduced.

## Additional operation bounds

PDF merge permits up to 100 pages without interactive form/signature fields. Images-to-PDF permits 1–20 JPG/PNG images, at most eight million pixels per image and 24 million pixels total; it checks dimensions before full image decoding. Optimization reuses the validated operation from 006. ZIP reuses its bounded archive operation. Outputs are at most 100 MiB and count against the managed-storage limit.

## Retention and recovery limits

Saved work persists until explicitly deleted; there is no automatic expiration in this batch. Committed originals/intermediate outputs are retained to support resumption and inspection. Scratch files are transient. A worker is not killed when a screen closes; processing can continue while the app remains alive, and a pause request is honored after the active step. If the OS terminates the process, startup changes running jobs to paused and removes only uncommitted work. No claim of uninterrupted background execution or power-loss durability beyond the filesystem's atomic replacement behavior is made.

The storage is OS app-private and excluded from automatic backup; it is not a newly implemented app-level encrypted vault. Uninstalling the app deletes its local work. Standalone tool histories/results and the session-only inbound sharing queue are not automatically migrated or retained here; users explicitly choose imports through Saved work. Lost/corrupted committed inputs require a new task using the original files. Native PDF merge behavior, device lock/backup behavior, real force-quit recovery and large-file performance still require device checks.

## Validation coverage

Filesystem and runner tests cover atomic import rollback, retained originals, quotas including metadata, stale revisions/cleanup, deletion without resurrection, missing/tampered content, orphan cleanup after interrupted steps, unsupported versions, path containment and symlink cleanup, safe pause, single-run locking, retry from a completed step, root relocation and explicit clear. Actual image-to-PDF → ZIP outputs are opened and inspected. Interface tests exercise file selection → saved processing → results, and both cancellation and confirmation of deletion.

Final command results are recorded below.

## Final checks — 15 October 2026

- `flutter test`: **111 passed** (84 existing + 27 saved-work/recovery/interface tests).
- `flutter analyze`: **eight pre-existing informational findings**, no analyzer errors/warnings and no new findings. Exit 1 reflects the informational baseline.
- `flutter build apk --debug`: **passed**, including the native private-storage channel.
- iOS simulator build: **passed** with the existing temporary compatibility overrides (`ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0`), including the native backup-excluded directory setup. This is not a signed release or validation on older supported devices.
- `git diff --check`: **passed**.
- Device acceptance pending: cold-start native channel availability, real process kill/relaunch, iOS locked-device behavior/backup exclusion, Android backup exclusion, native PDF merge fidelity, large-file performance and signed-release checks.

Rebuild/relaunch the app for the new native storage channel and startup service registration. Hot reload alone does not install native changes. Existing pending edits, dependency files, iOS project metadata and prior batches were preserved. No commits, pushes or store publication were performed.
