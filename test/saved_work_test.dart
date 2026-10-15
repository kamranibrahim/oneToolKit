import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:one_toolkit/modules/saved_work/saved_work_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:one_toolkit/data/saved_work/saved_job.dart';
import 'package:one_toolkit/data/saved_work/saved_operations.dart';
import 'package:one_toolkit/data/saved_work/saved_work_repository.dart';
import 'package:one_toolkit/data/services/saved_work_service.dart';

class ObservedSavedWorkService extends SavedWorkService {
  ObservedSavedWorkService(SavedWorkRepository repository)
    : super(repository: repository);
  final finished = Completer<void>();
  final deleted = Completer<void>();
  @override
  Future<void> run(String id) async {
    try {
      await super.run(id);
    } finally {
      if (!finished.isCompleted) finished.complete();
    }
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    if (!deleted.isCompleted) deleted.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sandbox;
  late Directory root;
  late File source;
  late SavedWorkRepository repo;
  const pdfStep = SavedStep(SavedOperation.optimizePdf, 'result.pdf');
  const zipStep = SavedStep(SavedOperation.zip, 'package.zip');
  List<SavedImport> inputs() => [
    SavedImport(source.path, 'original.pdf', 'application/pdf'),
  ];
  Future<SavedJob> create({List<SavedStep> steps = const [pdfStep]}) =>
      repo.create('Documents', inputs(), steps);
  Future<SavedOperationOutput> fake(
    SavedStep step,
    List<SavedOperationInput> inputs,
    Directory work,
  ) async {
    final file = File(p.join(work.path, 'result'));
    await file.writeAsString(
      '${await File(inputs.first.path).readAsString()} processed',
    );
    return SavedOperationOutput(
      file.path,
      step.operation == SavedOperation.zip
          ? 'application/zip'
          : 'application/pdf',
    );
  }

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('onetoolkit-saved-test');
    root = Directory(p.join(sandbox.path, 'saved'));
    repo = SavedWorkRepository(root);
    await repo.initialize();
    source = File(p.join(sandbox.path, 'source.pdf'));
    await source.writeAsString('original');
  });
  tearDown(() async {
    Get.reset();
    await sandbox.delete(recursive: true);
  });

  test(
    'imports are durable independent copies with stable IDs and verified hashes',
    () async {
      final job = await create();
      await source.delete();
      final reopened = await SavedWorkRepository(root).initialize();
      expect(reopened.single.id, job.id);
      final file = reopened.single.currentFiles.single;
      await repo.verify(reopened.single, file);
      expect(await File(repo.filePath(job, file)).readAsString(), 'original');
      expect(file.hash, hasLength(64));
    },
  );
  test(
    'a failed multi-file import leaves no partial saved job or staging files',
    () async {
      await expectLater(
        repo.create(
          'Files',
          [
            ...inputs(),
            SavedImport(
              '${sandbox.path}/missing',
              'missing.pdf',
              'application/pdf',
            ),
          ],
          [pdfStep],
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(root.listSync(), isEmpty);
      expect(await source.readAsString(), 'original');
    },
  );
  test('file and job quotas fail without overwriting existing work', () async {
    final limited = SavedWorkRepository(
      root,
      limits: const SavedWorkLimits(jobs: 1, fileBytes: 3),
    );
    await expectLater(
      limited.create('Too large', inputs(), [pdfStep]),
      throwsStateError,
    );
    expect(root.listSync(), isEmpty);
    final job = await create();
    await expectLater(
      SavedWorkRepository(
        root,
        limits: const SavedWorkLimits(jobs: 1),
      ).create('Other', inputs(), [pdfStep]),
      throwsStateError,
    );
    expect((await repo.read(job.id)).id, job.id);
  });
  test(
    'storage quota includes checkpoint overhead and rolls back an import',
    () async {
      final limited = SavedWorkRepository(
        root,
        limits: const SavedWorkLimits(totalBytes: 9),
      );
      await expectLater(
        limited.create('Too large', inputs(), [pdfStep]),
        throwsStateError,
      );
      expect(root.listSync(), isEmpty);
    },
  );
  test(
    'stale revisions are rejected without changing the committed checkpoint',
    () async {
      final original = await create();
      final changed = await repo.save(
        original.copy(status: SavedJobStatus.paused),
      );
      await expectLater(
        repo.save(original.copy(status: SavedJobStatus.failed)),
        throwsStateError,
      );
      expect((await repo.read(original.id)).revision, changed.revision);
      expect((await repo.read(original.id)).status, SavedJobStatus.paused);
    },
  );
  test(
    'deleting work cannot be undone by a stale write and leaves external originals',
    () async {
      final job = await create();
      await repo.delete(job.id);
      await expectLater(repo.save(job), throwsA(isA<FileSystemException>()));
      expect(root.listSync(), isEmpty);
      expect(await source.readAsString(), 'original');
    },
  );
  test(
    'startup pauses interrupted jobs and removes only uncommitted outputs',
    () async {
      var job = await create(steps: [pdfStep, zipStep]);
      job = await repo.save(job.copy(status: SavedJobStatus.running));
      final work = await repo.prepareWork(job);
      final output = File(p.join(work.path, 'orphan.pdf'));
      await output.writeAsString('uncommitted');
      final orphan = await repo.adopt(
        job,
        output.path,
        'orphan.pdf',
        'application/pdf',
      );
      await File(
        p.join(repo.directory(job.id).path, 'checkpoint.next'),
      ).writeAsString('incomplete write');
      final reopened = SavedWorkRepository(root);
      final recovered = (await reopened.initialize()).single;
      expect(recovered.status, SavedJobStatus.paused);
      expect(recovered.nextStep, 0);
      expect(
        File(
          p.join(repo.directory(job.id).path, orphan.relativePath),
        ).existsSync(),
        isFalse,
      );
      expect(work.existsSync(), isFalse);
      expect(
        File(
          p.join(repo.directory(job.id).path, 'checkpoint.next'),
        ).existsSync(),
        isFalse,
      );
      await reopened.verify(recovered, recovered.currentFiles.single);
    },
  );
  test(
    'unsupported checkpoint versions are reported and preserved verbatim',
    () async {
      final job = await create();
      final checkpoint = File(
        p.join(repo.directory(job.id).path, 'checkpoint.json'),
      );
      final future = jsonEncode({...job.toJson(), 'schemaVersion': 999});
      await checkpoint.writeAsString(future);
      expect(await repo.initialize(), isEmpty);
      expect(repo.warnings, hasLength(1));
      expect(await checkpoint.readAsString(), future);
      expect(
        File(repo.filePath(job, job.currentFiles.single)).existsSync(),
        isTrue,
      );
    },
  );
  test(
    'corrupt or escaping metadata is isolated without resetting healthy work',
    () async {
      final bad = await create();
      final healthy = await create();
      final json = bad.toJson();
      (json['artifacts'] as List).first['path'] = '../outside';
      await File(
        p.join(repo.directory(bad.id).path, 'checkpoint.json'),
      ).writeAsString(jsonEncode(json));
      final loaded = await repo.initialize();
      expect(loaded.map((j) => j.id), [healthy.id]);
      expect(repo.directory(bad.id).existsSync(), isTrue);
      expect(repo.warnings, isNotEmpty);
    },
  );
  test(
    'missing and same-length tampered files fail integrity validation',
    () async {
      final job = await create();
      final file = job.currentFiles.single;
      await File(repo.filePath(job, file)).writeAsString('tampered');
      await expectLater(repo.verify(job, file), throwsStateError);
      await File(repo.filePath(job, file)).delete();
      await expectLater(repo.verify(job, file), throwsStateError);
    },
  );
  test('outputs outside the job working directory are never adopted', () async {
    var job = await create();
    job = await repo.save(job.copy(status: SavedJobStatus.running));
    await expectLater(
      repo.adopt(job, source.path, 'outside.pdf', 'application/pdf'),
      throwsStateError,
    );
    expect(await source.readAsString(), 'original');
  });
  test(
    'incomplete import and deletion directories are cleaned on startup',
    () async {
      final stage = Directory(p.join(root.path, '.import-abandoned'));
      await stage.create();
      await File(p.join(stage.path, 'partial')).writeAsString('copy');
      final deleted = Directory(p.join(root.path, '.deleted-abandoned'));
      await deleted.create();
      await repo.initialize();
      expect(root.listSync(), isEmpty);
    },
  );

  test(
    'a failed later step resumes without rerunning or duplicating the committed step',
    () async {
      var fail = true;
      final calls = <SavedOperation>[];
      final service = await SavedWorkService(
        repository: repo,
        executor: (step, inputs, work) async {
          calls.add(step.operation);
          if (step.operation == SavedOperation.zip && fail) {
            throw StateError('Temporary failure');
          }
          return fake(step, inputs, work);
        },
      ).init();
      final job = await service.create('Documents', inputs(), [
        pdfStep,
        zipStep,
      ]);
      await service.run(job.id);
      final failed = service.find(job.id)!;
      expect(failed.status, SavedJobStatus.failed);
      expect(failed.nextStep, 1);
      expect(failed.artifacts, hasLength(2));
      expect(failed.currentFiles.single.name, 'result.pdf');
      fail = false;
      await service.run(job.id);
      final complete = service.find(job.id)!;
      expect(complete.status, SavedJobStatus.completed);
      expect(complete.artifacts, hasLength(3));
      expect(calls, [
        SavedOperation.optimizePdf,
        SavedOperation.zip,
        SavedOperation.zip,
      ]);
      await service.run(job.id);
      expect(calls, hasLength(3));
      final reopened = (await SavedWorkRepository(root).initialize()).single;
      expect(reopened.status, SavedJobStatus.completed);
      await repo.verify(reopened, reopened.currentFiles.single);
    },
  );
  test(
    'pause waits for a safe checkpoint and blocks duplicate runs/deletion/clear',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      var count = 0;
      final service = await SavedWorkService(
        repository: repo,
        executor: (step, inputs, work) async {
          if (count++ == 0) {
            started.complete();
            await finish.future;
          }
          return fake(step, inputs, work);
        },
      ).init();
      final job = await service.create('Documents', inputs(), [
        pdfStep,
        zipStep,
      ]);
      final running = service.run(job.id);
      await started.future;
      await expectLater(service.run(job.id), throwsStateError);
      await expectLater(service.delete(job.id), throwsStateError);
      await expectLater(service.clear(), throwsStateError);
      service.pause();
      finish.complete();
      await running;
      expect(service.find(job.id)!.status, SavedJobStatus.paused);
      expect(service.find(job.id)!.nextStep, 1);
      await service.run(job.id);
      expect(service.find(job.id)!.status, SavedJobStatus.completed);
      expect(count, 2);
    },
  );
  test(
    'relaunch resumes from a committed step with no reliance on picker paths',
    () async {
      var job = await create(steps: [pdfStep, zipStep]);
      job = await repo.save(job.copy(status: SavedJobStatus.running));
      final work = await repo.prepareWork(job);
      final result = await fake(pdfStep, [
        SavedOperationInput(
          repo.filePath(job, job.currentFiles.single),
          'original.pdf',
          'application/pdf',
        ),
      ], work);
      final file = await repo.adopt(
        job,
        result.path,
        'result.pdf',
        'application/pdf',
      );
      await repo.save(
        job.copy(
          nextStep: 1,
          artifacts: [...job.artifacts, file],
          currentIds: [file.id],
        ),
      );
      await source.delete();
      final calls = <SavedOperation>[];
      final service = await SavedWorkService(
        repository: SavedWorkRepository(root),
        executor: (step, inputs, work) async {
          calls.add(step.operation);
          return fake(step, inputs, work);
        },
      ).init();
      expect(service.find(job.id)!.status, SavedJobStatus.paused);
      await service.run(job.id);
      expect(calls, [SavedOperation.zip]);
      expect(service.find(job.id)!.status, SavedJobStatus.completed);
    },
  );
  test(
    'changed saved inputs stop a task before the executor is called',
    () async {
      var calls = 0;
      final service = await SavedWorkService(
        repository: repo,
        executor: (step, inputs, work) async {
          calls++;
          return fake(step, inputs, work);
        },
      ).init();
      final job = await service.create('Documents', inputs(), [pdfStep]);
      await File(repo.filePath(job, job.currentFiles.single)).delete();
      await service.run(job.id);
      expect(calls, 0);
      expect(service.find(job.id)!.status, SavedJobStatus.failed);
      expect(service.find(job.id)!.message, contains('missing'));
    },
  );
  test(
    'failed operation paths never persist or share an unrelated file',
    () async {
      final service = await SavedWorkService(
        repository: repo,
        executor: (step, inputs, work) async =>
            SavedOperationOutput(source.path, 'application/pdf'),
      ).init();
      final job = await service.create('Documents', inputs(), [pdfStep]);
      await service.run(job.id);
      expect(service.find(job.id)!.status, SavedJobStatus.failed);
      expect(service.find(job.id)!.artifacts, hasLength(1));
    },
  );
  test(
    'real image-to-PDF then ZIP adapter produces a durable reopenable package',
    () async {
      final image = File(p.join(sandbox.path, 'photo.png'));
      await image.writeAsBytes(img.encodePng(img.Image(width: 8, height: 4)));
      final service = await SavedWorkService(repository: repo).init();
      final job = await service.create(
        'Photos',
        [SavedImport(image.path, 'photo.png', 'image/png')],
        [const SavedStep(SavedOperation.imagesToPdf, 'photos.pdf'), zipStep],
      );
      await service.run(job.id);
      final complete = service.find(job.id)!;
      expect(
        complete.status,
        SavedJobStatus.completed,
        reason: complete.message,
      );
      final zip = ZipDecoder().decodeBytes(
        await File(
          repo.filePath(complete, complete.currentFiles.single),
        ).readAsBytes(),
      );
      expect(zip.files.single.name, 'photos.pdf');
      final pdf = PdfDocument(inputBytes: zip.files.single.content);
      try {
        expect(pdf.pages.count, 1);
        expect(pdf.pages[0].size.width, greaterThan(pdf.pages[0].size.height));
      } finally {
        pdf.dispose();
      }
    },
  );
  test(
    'unsupported step combinations are rejected before importing files',
    () async {
      final service = await SavedWorkService(repository: repo).init();
      await expectLater(
        service.create('Invalid', inputs(), [
          const SavedStep(SavedOperation.imagesToPdf, 'out.pdf'),
        ]),
        throwsFormatException,
      );
      expect(root.listSync(), isEmpty);
    },
  );
  test(
    'backup-excluded native storage is required rather than falling back silently',
    () async {
      const channel = MethodChannel('com.kamranibrahim.onetoolkit/saved_work');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'unavailable');
      });
      final service = await SavedWorkService().init();
      expect(service.ready, isFalse);
      expect(service.storageError.value, isNotNull);
      messenger.setMockMethodCallHandler(channel, null);
    },
  );
  test(
    'stale cleanup cannot delete outputs committed by a newer revision',
    () async {
      var job = await create();
      final old = job;
      job = await repo.save(job.copy(status: SavedJobStatus.running));
      final work = await repo.prepareWork(job);
      final output = File(p.join(work.path, 'result.pdf'));
      await output.writeAsString('committed');
      final artifact = await repo.adopt(
        job,
        output.path,
        'result.pdf',
        'application/pdf',
      );
      job = await repo.save(
        job.copy(
          status: SavedJobStatus.completed,
          nextStep: 1,
          artifacts: [...job.artifacts, artifact],
          currentIds: [artifact.id],
        ),
      );
      await expectLater(repo.clean(old), throwsStateError);
      await repo.verify(job, artifact);
    },
  );
  test(
    'startup never follows a substituted files-directory link during cleanup',
    () async {
      final job = await create();
      final originalFiles = Directory(
        p.join(repo.directory(job.id).path, 'files'),
      );
      await originalFiles.rename(
        p.join(repo.directory(job.id).path, 'held-files'),
      );
      final outside = Directory(p.join(sandbox.path, 'outside'));
      await outside.create();
      final protected = File(p.join(outside.path, 'keep.txt'));
      await protected.writeAsString('keep');
      await Link(originalFiles.path).create(outside.path);
      expect(await repo.initialize(), isEmpty);
      expect(repo.warnings, isNotEmpty);
      expect(await protected.readAsString(), 'keep');
    },
  );
  test(
    'clear removes managed work but preserves selected external originals',
    () async {
      final service = await SavedWorkService(repository: repo).init();
      await service.create('Files', inputs(), [pdfStep]);
      await service.clear();
      expect(service.jobs, isEmpty);
      expect(root.listSync(), isEmpty);
      expect(await source.readAsString(), 'original');
    },
  );

  testWidgets(
    'Saved work creates a guided image task with a durable document checklist',
    (tester) async {
      Get.testMode = true;
      FilePickerIO.registerWith();
      const picker = MethodChannel(
        'miguelruivo.flutter.plugins.filepicker',
        JSONMethodCodec(),
      );
      final bytes = img.encodePng(img.Image(width: 8, height: 4));
      source.writeAsBytesSync(bytes);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        picker,
        (call) async => [
          {
            'path': source.path,
            'name': 'photo.png',
            'size': bytes.length,
            'bytes': null,
          },
        ],
      );
      late ObservedSavedWorkService service;
      await tester.runAsync(() async {
        service = ObservedSavedWorkService(repo);
        await service.init();
      });
      Get.put<SavedWorkService>(service);
      await tester.pumpWidget(const GetMaterialApp(home: SavedWorkView()));
      expect(find.textContaining('No saved work yet'), findsOneWidget);
      await tester.tap(find.text('New task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start with a guide (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scanned document').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Choose files'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Choose files'));
      await tester.pumpAndSettle();
      expect(find.text('photo.png'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Save and run task'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Save and run task'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Save and run task'));
        await service.finished.future.timeout(const Duration(seconds: 15));
      });
      await tester.pumpAndSettle();
      expect(
        service.jobs.single.status,
        SavedJobStatus.completed,
        reason: service.jobs.single.message,
      );
      expect(find.textContaining('Completed'), findsOneWidget);
      expect(service.jobs.single.checklist.single.label, 'Document pages');
      expect(service.jobs.single.checklist.single.reviewed, isFalse);
      expect(service.jobs.single.requirements.isEmpty, isTrue);
      expect(
        service.jobs.single.currentFiles.single.name,
        'scanned_document.pdf',
      );
      await tester.scrollUntilVisible(
        find.text('Original imports'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SavedJobView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Original imports'), findsOneWidget);
      messenger.setMockMethodCallHandler(picker, null);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'deleting saved work requires confirmation and removes only app copies',
    (tester) async {
      Get.testMode = true;
      late ObservedSavedWorkService service;
      late SavedJob job;
      await tester.runAsync(() async {
        service = ObservedSavedWorkService(repo);
        await service.init();
        job = await service.create('Documents', inputs(), [pdfStep]);
      });
      Get.put<SavedWorkService>(service);
      await tester.pumpWidget(GetMaterialApp(home: SavedJobView(id: job.id)));
      await tester.scrollUntilVisible(
        find.text('Delete saved task and its files'),
        200,
      );
      await tester.runAsync(
        () => tester.tap(find.text('Delete saved task and its files')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(service.jobs, hasLength(1));
      await tester.runAsync(
        () => tester.tap(find.text('Delete saved task and its files')),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Delete'));
        await service.deleted.future;
      });
      await tester.pumpAndSettle();
      expect(service.jobs, isEmpty);
      expect(source.existsSync(), isTrue);
      expect(repo.directory(job.id).existsSync(), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  test(
    'relative artifact paths survive relocation of the app storage root',
    () async {
      final job = await create();
      final moved = await root.rename(p.join(sandbox.path, 'relocated'));
      final repository = SavedWorkRepository(moved);
      final reopened = (await repository.initialize()).single;
      expect(reopened.id, job.id);
      await repository.verify(reopened, reopened.currentFiles.single);
      expect(reopened.toJson().toString(), isNot(contains(sandbox.path)));
    },
  );
  test(
    'unsupported operation versions are preserved without running or cleanup',
    () async {
      final job = await create();
      final json = job.toJson();
      (json['steps'] as List).first['version'] = 999;
      final checkpoint = File(
        p.join(repo.directory(job.id).path, 'checkpoint.json'),
      );
      final contents = jsonEncode(json);
      await checkpoint.writeAsString(contents);
      expect(await repo.initialize(), isEmpty);
      expect(await checkpoint.readAsString(), contents);
      expect(repo.warnings, isNotEmpty);
    },
  );
}
