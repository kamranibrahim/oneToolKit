import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:one_toolkit/modules/saved_work/saved_work_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:one_toolkit/data/saved_work/saved_job.dart';
import 'package:one_toolkit/data/saved_work/saved_work_repository.dart';
import 'package:one_toolkit/data/saved_work/submission_requirements.dart';
import 'package:one_toolkit/data/services/saved_work_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late File pdf;
  late SavedWorkRepository repo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('submission-test');
    pdf = File('${dir.path}/source.pdf');
    final document = PdfDocument();
    document.pages.add();
    document.pages.add();
    await pdf.writeAsBytes(await document.save());
    document.dispose();
    repo = SavedWorkRepository(Directory('${dir.path}/saved'));
    await repo.initialize();
  });
  tearDown(() async {
    Get.reset();
    await dir.delete(recursive: true);
  });
  Future<SavedJob> create(SubmissionRequirements rules) => repo.create(
    'Application',
    [SavedImport(pdf.path, 'source.pdf', 'application/pdf')],
    [const SavedStep(SavedOperation.optimizePdf, 'prepared.pdf')],
    requirements: rules,
  );

  testWidgets('routine prefills rules but requires fresh file selection', (
    tester,
  ) async {
    late SavedWorkService service;
    late SavedJob job;
    await tester.runAsync(() async {
      job = await create(
        SubmissionRequirements(
          maxBytes: 20000,
          maxPages: 2,
          format: 'pdf',
          exactName: 'prepared.pdf',
        ),
      );
      service = await SavedWorkService(repository: repo).init();
      await service.saveRoutine(job);
    });
    Get.testMode = true;
    Get.put<SavedWorkService>(service);
    await tester.pumpWidget(
      GetMaterialApp(home: NewSavedWorkView(routine: service.routines.single)),
    );
    await tester.tap(find.text('Submission requirements (optional)'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '20000'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save and run task'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save and run task'),
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('checks actual PDF size, pages, exact filename and format', () async {
    final checks = await SubmissionValidator.check(
      pdf.path,
      'source.pdf',
      SubmissionRequirements(
        maxBytes: await pdf.length(),
        maxPages: 2,
        format: 'pdf',
        exactName: 'source.pdf',
      ),
    );
    expect(checks, hasLength(4));
    expect(
      checks.every((c) => c.status == SubmissionCheckStatus.passed),
      isTrue,
    );
    final failing = await SubmissionValidator.check(
      pdf.path,
      'source.pdf',
      SubmissionRequirements(
        maxBytes: 1,
        maxPages: 1,
        format: 'zip',
        exactName: 'other.pdf',
      ),
    );
    expect(
      failing.every((c) => c.status == SubmissionCheckStatus.failed),
      isTrue,
    );
  });
  test(
    'renamed garbage fails signature rule and page check stays unresolved',
    () async {
      await pdf.writeAsString('garbage');
      final checks = await SubmissionValidator.check(
        pdf.path,
        'source.pdf',
        SubmissionRequirements(format: 'pdf', maxPages: 2),
      );
      expect(checks.map((c) => c.status), [
        SubmissionCheckStatus.failed,
        SubmissionCheckStatus.unresolved,
      ]);
    },
  );
  test('ZIP page requirements never silently pass', () async {
    await pdf.writeAsBytes([80, 75, 3, 4, 0, 0, 0, 0]);
    final checks = await SubmissionValidator.check(
      pdf.path,
      'source.zip',
      SubmissionRequirements(format: 'zip', maxPages: 2),
    );
    expect(checks.last.status, SubmissionCheckStatus.unresolved);
  });
  test('malformed PDF cannot claim a readable page count', () async {
    await pdf.writeAsString('%PDF- broken');
    final checks = await SubmissionValidator.check(
      pdf.path,
      'source.pdf',
      SubmissionRequirements(maxPages: 2),
    );
    expect(checks.single.status, SubmissionCheckStatus.unresolved);
  });
  test(
    'invalid rules reject unsafe names, unsupported formats and invalid limits',
    () {
      for (final call in [
        () => SubmissionRequirements(maxBytes: 0),
        () => SubmissionRequirements(maxPages: 101),
        () => SubmissionRequirements(format: 'exe'),
        () => SubmissionRequirements(exactName: '../escape.pdf'),
      ]) {
        expect(call, throwsFormatException);
      }
    },
  );
  test(
    'requirements survive checkpoints and v1 migrates without rules',
    () async {
      final job = await create(
        SubmissionRequirements(
          maxBytes: 12345,
          maxPages: 2,
          format: 'pdf',
          exactName: 'prepared.pdf',
        ),
      );
      expect(
        (await repo.read(job.id)).requirements.toJson(),
        job.requirements.toJson(),
      );
      expect(
        job.copy(revision: 1).requirements.toJson(),
        job.requirements.toJson(),
      );
      final old = {...job.toJson(), 'schemaVersion': 1}..remove('requirements');
      expect(SavedJob.fromJson(old).requirements.isEmpty, isTrue);
    },
  );
  test(
    'routine outlives source job and contains settings without file paths',
    () async {
      final job = await create(SubmissionRequirements(maxPages: 2));
      final routine = await repo.saveRoutine(job);
      await repo.delete(job.id);
      final loaded = (await repo.loadRoutines()).single;
      expect(loaded.id, routine.id);
      expect(loaded.steps.single.outputName, 'prepared.pdf');
      expect(loaded.requirements.maxPages, 2);
      expect(jsonEncode(loaded.toJson()), isNot(contains(pdf.path)));
      final fresh = await repo.create(
        loaded.title,
        [SavedImport(pdf.path, 'new.pdf', 'application/pdf')],
        loaded.steps,
        requirements: loaded.requirements,
      );
      expect(fresh.currentFiles.single.name, 'new.pdf');
      await repo.deleteRoutine(routine.id);
      expect(await repo.loadRoutines(), isEmpty);
    },
  );
  test(
    'future and corrupt routines are preserved with a visible warning',
    () async {
      final job = await create(SubmissionRequirements());
      final routine = await repo.saveRoutine(job);
      final file = File('${repo.root.path}/routines/${routine.id}.json');
      final future = jsonEncode({...routine.toJson(), 'schemaVersion': 999});
      await file.writeAsString(future);
      expect(await repo.loadRoutines(), isEmpty);
      expect(repo.warnings, isNotEmpty);
      expect(await file.readAsString(), future);
    },
  );
  test('clear removes routines but keeps chosen originals', () async {
    await repo.saveRoutine(await create(SubmissionRequirements()));
    await repo.clear();
    expect(await repo.loadRoutines(), isEmpty);
    expect(await pdf.exists(), isTrue);
  });
  test(
    'validation refuses unfinished jobs and detects changed exports',
    () async {
      var job = await create(SubmissionRequirements(maxPages: 2));
      final service = await SavedWorkService(repository: repo).init();
      await expectLater(service.checkSubmission(job.id), throwsStateError);
      job = await repo.save(
        job.copy(nextStep: 1, status: SavedJobStatus.completed),
      );
      expect(
        (await service.checkSubmission(job.id)).single.status,
        SubmissionCheckStatus.passed,
      );
      await File(
        repo.filePath(job, job.currentFiles.single),
      ).writeAsString('changed');
      await expectLater(service.checkSubmission(job.id), throwsStateError);
    },
  );
}
