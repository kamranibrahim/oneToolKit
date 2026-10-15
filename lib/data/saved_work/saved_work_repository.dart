import 'submission_checklist.dart';
import 'saved_routine.dart';
import 'submission_requirements.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../processing/file_names.dart';
import 'saved_job.dart';

class SavedImport {
  const SavedImport(this.path, this.name, this.mime);
  final String path, name, mime;
}

class SavedWorkLimits {
  const SavedWorkLimits({
    this.jobs = 50,
    this.totalBytes = 500 * 1024 * 1024,
    this.jobInputBytes = 100 * 1024 * 1024,
    this.fileBytes = 50 * 1024 * 1024,
  });
  final int jobs, totalBytes, jobInputBytes, fileBytes;
}

/// A checkpoint is the transaction boundary; file IDs are immutable. Only this
/// repository writes metadata. It never interprets arbitrary paths from disk.
class SavedWorkRepository {
  SavedWorkRepository(this.root, {this.limits = const SavedWorkLimits()});
  final Directory root;
  final SavedWorkLimits limits;
  final warnings = <String>[];
  Future<void> _tail = Future.value();
  static const _uuid = Uuid();

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Directory directory(String id) {
    if (!SavedJob.validId(id)) throw const FormatException('Invalid job ID.');
    return Directory(p.join(root.path, id));
  }

  String filePath(SavedJob job, SavedArtifact artifact) {
    if (!job.artifacts.any(
      (f) => f.id == artifact.id && f.relativePath == artifact.relativePath,
    )) {
      throw const FormatException('File does not belong to this work.');
    }
    return p.join(directory(job.id).path, artifact.relativePath);
  }

  Future<int> diskBytes() async {
    var bytes = 0;
    if (!await root.exists()) return 0;
    await for (final file in root.list(recursive: true, followLinks: false)) {
      if (file is File) bytes += await file.length();
    }
    return bytes;
  }

  Future<String> _hash(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  Future<List<SavedJob>> initialize() => _locked(() async {
    await root.create(recursive: true);
    warnings.clear();
    final jobs = <SavedJob>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final id = p.basename(entity.path);
      if (id.startsWith('.import-') || id.startsWith('.deleted-')) {
        await entity.delete(recursive: true);
        continue;
      }
      if (!SavedJob.validId(id)) continue;
      try {
        var job = await _read(id);
        if (job.status == SavedJobStatus.running) {
          job = job.copy(
            status: SavedJobStatus.paused,
            revision: job.revision + 1,
            message: 'Interrupted. Resume from the last completed step.',
          );
          await _write(job);
        }
        await _clean(job);
        jobs.add(job);
      } catch (_) {
        warnings.add('One saved job could not be opened. Its files were kept.');
      }
    }
    jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return jobs;
  });

  Future<SavedJob> _read(String id) async {
    if (await FileSystemEntity.type(directory(id).path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw FileSystemException(
        'Saved directory is unavailable',
        directory(id).path,
      );
    }
    final checkpoint = File(p.join(directory(id).path, 'checkpoint.json'));
    if (await FileSystemEntity.type(checkpoint.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await checkpoint.length() > 1024 * 1024) {
      throw const FormatException('Saved checkpoint is invalid.');
    }
    final data = jsonDecode(await checkpoint.readAsString());
    final job = SavedJob.fromJson(Map<String, dynamic>.from(data));
    if (job.id != id) throw const FormatException('Saved job ID mismatch.');
    return job;
  }

  Future<SavedJob> read(String id) => _locked(() => _read(id));
  Future<void> _write(SavedJob job, {Directory? target}) async {
    final dir = target ?? directory(job.id);
    final pending = File(p.join(dir.path, 'checkpoint.next'));
    await pending.writeAsString(jsonEncode(job.toJson()), flush: true);
    await pending.rename(p.join(dir.path, 'checkpoint.json'));
  }

  Future<SavedJob> save(SavedJob job) => _locked(() async {
    final existing = await _read(
      job.id,
    ); // Deleted jobs can never be recreated.
    if (existing.revision != job.revision) {
      throw StateError('Saved work changed. Reopen it and try again.');
    }
    final updated = job.copy(revision: job.revision + 1, message: job.message);
    await _write(updated);
    return updated;
  });

  Future<Directory> _routineDirectory({bool create = true}) async {
    final dir = Directory(p.join(root.path, 'routines'));
    final type = await FileSystemEntity.type(dir.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      throw StateError('Routine storage could not be opened.');
    }
    return create ? dir.create(recursive: true) : dir;
  }

  Future<List<SavedRoutine>> loadRoutines() => _locked(() async {
    final dir = await _routineDirectory(create: false);
    final result = <SavedRoutine>[];
    if (!await dir.exists()) return result;
    await for (final entry in dir.list(followLinks: false)) {
      if (entry.path.endsWith('.next') &&
          SavedJob.validId(p.basenameWithoutExtension(entry.path))) {
        await entry.delete();
        continue;
      }
      if (!entry.path.endsWith('.json')) continue;
      try {
        if (await FileSystemEntity.type(entry.path, followLinks: false) !=
                FileSystemEntityType.file ||
            await File(entry.path).length() > 16384) {
          throw const FormatException();
        }
        final routine = SavedRoutine.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(await File(entry.path).readAsString()) as Map,
          ),
        );
        if (p.basename(entry.path) != '${routine.id}.json') {
          throw const FormatException();
        }
        result.add(routine);
      } catch (_) {
        warnings.add(
          'One routine could not be opened. Its settings were kept.',
        );
      }
    }
    return result;
  });

  Future<SavedRoutine> saveRoutine(SavedJob job) => _locked(() async {
    final dir = await _routineDirectory();
    if ((await dir.list().toList()).length >= 50) {
      throw StateError('Delete a routine before saving another (maximum 50).');
    }
    final routine = SavedRoutine(
      _uuid.v4(),
      job.title,
      job.steps,
      job.requirements,
      checklist: job.checklist,
    );
    final data = jsonEncode(routine.toJson());
    if (utf8.encode(data).length > 16384 ||
        await diskBytes() + utf8.encode(data).length > limits.totalBytes) {
      throw StateError('Saved-work storage limit exceeded.');
    }
    final temporary = File(p.join(dir.path, '${routine.id}.next'));
    await temporary.writeAsString(data, flush: true);
    await temporary.rename(p.join(dir.path, '${routine.id}.json'));
    return routine;
  });

  Future<void> deleteRoutine(String id) => _locked(() async {
    if (!SavedJob.validId(id)) throw const FormatException('Invalid routine.');
    final dir = await _routineDirectory();
    await File(p.join(dir.path, '$id.json')).delete();
  });

  Future<SavedJob> create(
    String title,
    List<SavedImport> inputs,
    List<SavedStep> steps, {
    SubmissionRequirements? requirements,
    List<SubmissionChecklistItem> checklist = const [],
  }) => _locked(() async {
    await root.create(recursive: true);
    if (inputs.isEmpty || inputs.length > 100) {
      throw const FormatException('Choose 1–100 files.');
    }
    final count =
        (await root
                .list(followLinks: false)
                .where((e) => SavedJob.validId(p.basename(e.path)))
                .toList())
            .length;
    if (count >= limits.jobs) {
      throw StateError(
        'Saved work is full. Delete a job before adding another.',
      );
    }
    final id = _uuid.v4();
    final stage = Directory(p.join(root.path, '.import-$id'));
    await stage.create();
    try {
      final artifacts = <SavedArtifact>[];
      var imported = 0;
      var available = limits.totalBytes - await diskBytes();
      for (final input in inputs) {
        FileNames.validate(input.name);
        final artifactId = _uuid.v4();
        final relative = 'files/$artifactId/${input.name}';
        final target = File(p.join(stage.path, relative));
        await target.parent.create(recursive: true);
        final sink = target.openWrite();
        var bytes = 0;
        try {
          await for (final chunk in File(input.path).openRead()) {
            bytes += chunk.length;
            if (bytes > limits.fileBytes ||
                imported + bytes > limits.jobInputBytes ||
                bytes > available) {
              throw StateError('File or saved-work storage limit exceeded.');
            }
            sink.add(chunk);
            await sink.flush();
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        if (bytes == 0) {
          throw const FormatException(
            'Empty files cannot be used in this task.',
          );
        }
        available -= bytes;
        imported += bytes;
        artifacts.add(
          SavedArtifact(
            id: artifactId,
            name: input.name,
            mime: input.mime,
            relativePath: relative,
            bytes: bytes,
            hash: await _hash(target),
            sourceIds: const [],
          ),
        );
      }
      final now = DateTime.now();
      final job = SavedJob(
        id: id,
        title: title.trim(),
        requirements: requirements,
        checklist: checklist,
        createdAt: now,
        updatedAt: now,
        status: SavedJobStatus.queued,
        steps: steps,
        artifacts: artifacts,
        currentIds: artifacts.map((f) => f.id).toList(),
        nextStep: 0,
      );
      await _write(job, target: stage);
      if (await diskBytes() > limits.totalBytes) {
        throw StateError('Saved-work storage limit exceeded.');
      }
      await stage.rename(directory(id).path);
      return job;
    } catch (_) {
      if (await stage.exists()) await stage.delete(recursive: true);
      rethrow;
    }
  });

  Future<void> verify(SavedJob job, SavedArtifact artifact) async {
    final file = File(filePath(job, artifact));
    final safeRoot = await directory(job.id).resolveSymbolicLinks();
    if (!await file.exists() ||
        !p.isWithin(safeRoot, await file.resolveSymbolicLinks()) ||
        await file.length() != artifact.bytes ||
        await _hash(file) != artifact.hash) {
      throw StateError(
        'A saved file is missing or has changed. Start a new task with the original files.',
      );
    }
  }

  /// Stage an output before committing its ID in the next checkpoint. A crash
  /// here leaves an orphan, removed during startup or before retry.
  Future<SavedArtifact> adopt(
    SavedJob job,
    String sourcePath,
    String name,
    String mime,
  ) => _locked(() async {
    final existing = await _read(job.id);
    if (job.revision != existing.revision) {
      throw StateError('Saved work changed.');
    }
    FileNames.validate(name);
    for (final artifact in job.artifacts) {
      if (p.equals(sourcePath, filePath(job, artifact))) return artifact;
    }
    final work = p.join(directory(job.id).path, '.work');
    if (!p.isWithin(work, p.normalize(sourcePath)) ||
        await FileSystemEntity.type(sourcePath, followLinks: false) !=
            FileSystemEntityType.file) {
      throw StateError('Task returned a file outside its working area.');
    }
    final source = File(sourcePath);
    final bytes = await source.length();
    if (bytes == 0 ||
        bytes > 100 * 1024 * 1024 ||
        await diskBytes() > limits.totalBytes) {
      throw StateError('Result exceeds the saved-work storage limit.');
    }
    final id = _uuid.v4();
    final relative = 'files/$id/$name';
    final destination = File(p.join(directory(job.id).path, relative));
    final hash = await _hash(source);
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    return SavedArtifact(
      id: id,
      name: name,
      mime: mime,
      relativePath: relative,
      bytes: bytes,
      hash: hash,
      sourceIds: job.currentIds,
    );
  });

  Future<void> _clean(SavedJob job) async {
    for (final folder in [
      directory(job.id).path,
      p.join(directory(job.id).path, 'files'),
      p.join(directory(job.id).path, '.work'),
    ]) {
      if (await FileSystemEntity.type(folder, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const FormatException('Invalid saved directory.');
      }
    }
    final work = Directory(p.join(directory(job.id).path, '.work'));
    if (await work.exists()) await work.delete(recursive: true);
    final files = Directory(p.join(directory(job.id).path, 'files'));
    if (!await files.exists()) return;
    final ids = job.artifacts.map((f) => f.id).toSet();
    await for (final entry in files.list(followLinks: false)) {
      if (!ids.contains(p.basename(entry.path))) {
        await entry.delete(recursive: true);
      }
    }
    final pending = File(p.join(directory(job.id).path, 'checkpoint.next'));
    if (await pending.exists()) await pending.delete();
  }

  Future<Directory> prepareWork(SavedJob job) => _locked(() async {
    final live = await _read(job.id);
    if (live.revision != job.revision) throw StateError('Saved work changed.');
    await _clean(live);
    return Directory(p.join(directory(job.id).path, '.work')).create();
  });
  Future<void> clean(SavedJob job) => _locked(() async {
    final live = await _read(job.id);
    if (live.revision != job.revision) throw StateError('Saved work changed.');
    await _clean(live);
  });

  Future<void> delete(String id) => _locked(() async {
    final dir = directory(id);
    if (!await dir.exists()) return;
    final tombstone = await dir.rename(p.join(root.path, '.deleted-$id'));
    await tombstone.delete(recursive: true);
  });
  Future<void> clear() => _locked(() async {
    if (!await root.exists()) return;
    await for (final entry in root.list(followLinks: false)) {
      await entry.delete(recursive: true);
    }
    warnings.clear();
  });
}
