import '../saved_work/submission_checklist.dart';
import '../saved_work/saved_routine.dart';
import '../saved_work/submission_requirements.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../saved_work/saved_job.dart';
import '../saved_work/saved_operations.dart';
import '../saved_work/saved_work_repository.dart';

class SavedWorkService extends GetxService {
  SavedWorkService({SavedWorkRepository? repository, SavedExecutor? executor})
    : _repository = repository,
      _executor = executor ?? SavedOperations.execute;
  SavedWorkRepository? _repository;
  final SavedExecutor _executor;
  final routines = <SavedRoutine>[].obs;
  final jobs = <SavedJob>[].obs;
  final warnings = <String>[].obs;
  final storageError = RxnString();
  final activeId = RxnString();
  final importing = false.obs;
  final pauseRequested = false.obs;
  bool get ready => _repository != null && storageError.value == null;
  SavedWorkRepository get repository {
    if (!ready) throw StateError('Saved storage is unavailable. Try again.');
    return _repository!;
  }

  Future<SavedWorkService> init() async {
    if (activeId.value != null || importing.value) return this;
    try {
      if (_repository == null) {
        final path = await const MethodChannel(
          'com.kamranibrahim.onetoolkit/saved_work',
        ).invokeMethod<String>('directory');
        if (path == null || path.isEmpty) {
          throw StateError('Private saved storage is unavailable.');
        }
        _repository = SavedWorkRepository(Directory(path));
      }
      jobs.assignAll(await _repository!.initialize());
      routines.assignAll(await _repository!.loadRoutines());
      warnings.assignAll(_repository!.warnings);
      storageError.value = null;
    } catch (_) {
      storageError.value =
          'Saved work could not be opened. Your existing files have not been reset.';
    }
    return this;
  }

  SavedJob? find(String id) => jobs.firstWhereOrNull((job) => job.id == id);
  void _publish(SavedJob job) {
    final index = jobs.indexWhere((j) => j.id == job.id);
    if (index < 0) {
      jobs.insert(0, job);
    } else {
      jobs[index] = job;
    }
  }

  Future<SavedJob> create(
    String title,
    List<SavedImport> inputs,
    List<SavedStep> steps, {
    SubmissionRequirements? requirements,
    List<SubmissionChecklistItem> checklist = const [],
  }) async {
    if (importing.value) {
      throw StateError('Another import is still being saved.');
    }
    if (title.trim().isEmpty) throw const FormatException('Enter a task name.');
    SavedOperations.validatePlan(steps, inputs.map((f) => f.mime).toList());
    importing.value = true;
    try {
      final job = await repository.create(
        title,
        inputs,
        steps,
        requirements: requirements,
        checklist: checklist,
      );
      _publish(job);
      return job;
    } finally {
      importing.value = false;
    }
  }

  Future<void> saveRoutine(SavedJob job) async {
    if (importing.value) {
      throw StateError('Wait for the current save to finish.');
    }
    importing.value = true;
    try {
      routines.add(await repository.saveRoutine(job));
    } finally {
      importing.value = false;
    }
  }

  Future<void> deleteRoutine(String id) async {
    if (importing.value) {
      throw StateError('Wait for the current save to finish.');
    }
    importing.value = true;
    try {
      await repository.deleteRoutine(id);
      routines.removeWhere((r) => r.id == id);
    } finally {
      importing.value = false;
    }
  }

  Future<void> updateChecklist(
    String id,
    List<SubmissionChecklistItem> checklist,
  ) async {
    if (activeId.value != null || importing.value) {
      throw StateError(
        'Wait for the active task or save before editing the checklist.',
      );
    }
    importing.value = true;
    try {
      final job = await repository.read(id);
      final updated = await repository.save(
        job.copy(checklist: checklist, message: job.message),
      );
      _publish(updated);
    } finally {
      importing.value = false;
    }
  }

  Future<List<SubmissionCheck>> checkSubmission(String id) async {
    final job = await repository.read(id);
    if (job.status != SavedJobStatus.completed) {
      throw StateError('Finish processing before checking the export.');
    }
    final checks = <SubmissionCheck>[];
    for (final item in job.checklist) {
      for (final id in item.artifactIds) {
        await repository.verify(
          job,
          job.artifacts.firstWhere((file) => file.id == id),
        );
      }
      checks.add(
        SubmissionCheck(
          item.artifactIds.isEmpty || !item.reviewed
              ? SubmissionCheckStatus.unresolved
              : SubmissionCheckStatus.passed,
          '${item.label}: ${item.artifactIds.isEmpty
              ? 'no saved file linked'
              : item.reviewed
              ? 'linked files reviewed by you'
              : 'linked files still need your review'}.',
        ),
      );
    }
    for (final file in job.currentFiles) {
      await repository.verify(job, file);
      checks.addAll(
        await SubmissionValidator.check(
          repository.filePath(job, file),
          file.name,
          job.requirements,
        ),
      );
    }
    return checks;
  }

  Future<void> run(String id) async {
    if (activeId.value != null || importing.value) {
      throw StateError('Wait for the active task or save to finish.');
    }
    activeId.value = id;
    pauseRequested.value = false;
    SavedJob? job;
    try {
      job = await repository.read(id);
      if (job.status == SavedJobStatus.completed) return;
      SavedOperations.validatePlan(
        job.steps.skip(job.nextStep).toList(),
        job.currentFiles.map((f) => f.mime).toList(),
      );
      while (job!.nextStep < job.steps.length) {
        if (pauseRequested.value) {
          job = await repository.save(
            job.copy(
              status: SavedJobStatus.paused,
              message: 'Paused before the next step.',
            ),
          );
          _publish(job);
          return;
        }
        for (final file in job.currentFiles) {
          await repository.verify(job, file);
        }
        job = await repository.save(job.copy(status: SavedJobStatus.running));
        _publish(job);
        final work = await repository.prepareWork(job);
        final inputs = job.currentFiles
            .map(
              (f) => SavedOperationInput(
                repository.filePath(job!, f),
                f.name,
                f.mime,
              ),
            )
            .toList();
        final step = job.steps[job.nextStep];
        final result = await _executor(step, inputs, work);
        final expectedMime = step.operation == SavedOperation.zip
            ? 'application/zip'
            : 'application/pdf';
        if (result.mime != expectedMime) {
          throw StateError('Task returned an unexpected file type.');
        }
        final artifact = await repository.adopt(
          job,
          result.path,
          step.outputName,
          result.mime,
        );
        final next = job.nextStep + 1;
        job = await repository.save(
          job.copy(
            status: next == job.steps.length
                ? SavedJobStatus.completed
                : SavedJobStatus.running,
            nextStep: next,
            artifacts: [
              ...job.artifacts.where((f) => f.id != artifact.id),
              artifact,
            ],
            currentIds: [artifact.id],
            message: result.message,
          ),
        );
        _publish(job);
        try {
          await repository.clean(job);
        } catch (_) {
          warnings.add(
            'Temporary task files will be cleaned up when saved work reopens.',
          );
        }
      }
    } catch (error) {
      if (job != null) {
        try {
          job = await repository.save(
            job.copy(
              status: SavedJobStatus.failed,
              message: error
                  .toString()
                  .replaceFirst('Bad state: ', '')
                  .replaceFirst('FormatException: ', ''),
            ),
          );
          _publish(job);
          await repository.clean(job);
        } catch (_) {
          storageError.value =
              'This task could not be updated. Reopen Saved work to recover it.';
        }
      } else {
        storageError.value =
            'This saved task could not be opened. Its files have not been reset.';
      }
    } finally {
      activeId.value = null;
      pauseRequested.value = false;
    }
  }

  void pause() {
    if (activeId.value != null) pauseRequested.value = true;
  }

  Future<void> delete(String id) async {
    if (activeId.value == id || importing.value) {
      throw StateError(
        'Pause the task and wait for the current step to finish before deleting.',
      );
    }
    await repository.delete(id);
    jobs.removeWhere((j) => j.id == id);
  }

  Future<void> clear() async {
    if (activeId.value != null || importing.value) {
      throw StateError(
        'Wait for the active task or import before clearing saved work.',
      );
    }
    await repository.clear();
    jobs.clear();
    routines.clear();
    warnings.clear();
  }
}
