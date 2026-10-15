import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:one_toolkit/data/saved_work/saved_job.dart';
import 'package:one_toolkit/data/saved_work/saved_work_repository.dart';
import 'package:one_toolkit/data/saved_work/saved_routine.dart';
import 'package:one_toolkit/data/saved_work/submission_checklist.dart';
import 'package:one_toolkit/data/saved_work/submission_requirements.dart';
import 'package:one_toolkit/data/services/saved_work_service.dart';
import 'package:one_toolkit/modules/saved_work/saved_work_view.dart';
import 'package:one_toolkit/modules/saved_work/submission_checklist_editor.dart';

const itemId = '11111111-1111-1111-1111-111111111111';
const otherId = '22222222-2222-2222-2222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late File original;
  late SavedWorkRepository repository;
  late SavedWorkService service;
  Future<SavedJob> create() => service.create(
    'Application',
    [SavedImport(original.path, 'document.txt', 'text/plain')],
    [const SavedStep(SavedOperation.zip, 'application.zip')],
    checklist: [
      SubmissionChecklistItem(id: itemId, label: 'Main document'),
      SubmissionChecklistItem(id: otherId, label: 'Supporting document'),
    ],
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('checklist-test');
    original = await File(
      '${dir.path}/original.txt',
    ).writeAsString('document contents');
    repository = SavedWorkRepository(Directory('${dir.path}/saved'));
    service = await SavedWorkService(repository: repository).init();
  });
  tearDown(() async {
    Get.reset();
    await dir.delete(recursive: true);
  });

  test(
    'checklist distinguishes missing, linked and reviewed with durable state',
    () async {
      var job = await create();
      await service.run(job.id);
      var checks = await service.checkSubmission(job.id);
      expect(
        checks.map((c) => c.status),
        everyElement(SubmissionCheckStatus.unresolved),
      );
      job = service.find(job.id)!;
      final linked = job.checklist.first.copy(
        artifactIds: [job.artifacts.first.id],
      );
      await service.updateChecklist(job.id, [linked, job.checklist.last]);
      expect(
        (await service.checkSubmission(job.id)).first.status,
        SubmissionCheckStatus.unresolved,
      );
      await service.updateChecklist(job.id, [
        linked.copy(reviewed: true),
        job.checklist.last,
      ]);
      final reopened = await repository.read(job.id);
      expect(reopened.checklist.first.reviewed, isTrue);
      checks = await service.checkSubmission(job.id);
      expect(checks.first.status, SubmissionCheckStatus.passed);
      expect(checks.first.message, contains('reviewed by you'));
      expect(checks.last.status, SubmissionCheckStatus.unresolved);
    },
  );
  test('edited labels or links always reset review', () {
    final reviewed = SubmissionChecklistItem(
      id: itemId,
      label: 'Document',
      artifactIds: [otherId],
      reviewed: true,
    );
    expect(
      reviewed.copy(label: 'Updated document', reviewed: true).reviewed,
      isFalse,
    );
    expect(
      reviewed.copy(artifactIds: [otherId], reviewed: true).reviewed,
      isFalse,
    );
    expect(reviewed.copy(reviewed: false).reviewed, isFalse);
  });
  test(
    'checklist refuses invalid IDs, empty labels, excessive items and review without files',
    () {
      expect(
        () => SubmissionChecklistItem(id: itemId, label: '  '),
        throwsFormatException,
      );
      expect(
        () => SubmissionChecklistItem(id: 'bad', label: 'Document'),
        throwsFormatException,
      );
      expect(
        () => SubmissionChecklistItem(
          id: itemId,
          label: 'Document',
          reviewed: true,
        ),
        throwsFormatException,
      );
      final item = SubmissionChecklistItem(id: itemId, label: 'Document');
      expect(
        () => SubmissionChecklistItem.validate([item, item]),
        throwsFormatException,
      );
      expect(
        () => SubmissionChecklistItem.validate(List.generate(31, (_) => item)),
        throwsFormatException,
      );
    },
  );
  test(
    'unknown saved-file references are rejected without modifying checkpoint',
    () async {
      final job = await create();
      await expectLater(
        service.updateChecklist(job.id, [
          job.checklist.first.copy(artifactIds: [otherId]),
        ]),
        throwsFormatException,
      );
      expect((await repository.read(job.id)).revision, job.revision);
      expect(service.importing.value, isFalse);
    },
  );
  test(
    'reviewed source tampering is detected on every submission check',
    () async {
      var job = await create();
      await service.run(job.id);
      job = service.find(job.id)!;
      await service.updateChecklist(job.id, [
        job.checklist.first
            .copy(artifactIds: [job.artifacts.first.id])
            .copy(reviewed: true),
      ]);
      await File(
        repository.filePath(job, job.artifacts.first),
      ).writeAsString('tampered');
      await expectLater(service.checkSubmission(job.id), throwsStateError);
    },
  );
  test(
    'routine excludes checklist file IDs and review state and survives job deletion',
    () async {
      final job = await create();
      await service.updateChecklist(job.id, [
        job.checklist.first
            .copy(artifactIds: [job.artifacts.first.id])
            .copy(reviewed: true),
      ]);
      await service.saveRoutine(service.find(job.id)!);
      await service.delete(job.id);
      final routine = (await repository.loadRoutines()).single;
      expect(routine.checklist.single.label, 'Main document');
      expect(routine.checklist.single.artifactIds, isEmpty);
      expect(routine.checklist.single.reviewed, isFalse);
      expect(
        jsonEncode(routine.toJson()),
        isNot(contains(job.artifacts.first.id)),
      );
    },
  );
  test('older job and routine schemas load with empty checklists', () async {
    final job = await create();
    for (final version in [1, 2]) {
      final old = {...job.toJson(), 'schemaVersion': version}
        ..remove('checklist');
      expect(SavedJob.fromJson(old).checklist, isEmpty);
    }
    final routine = await repository.saveRoutine(job);
    final old = {...routine.toJson(), 'schemaVersion': 1}..remove('checklist');
    expect(SavedRoutine.fromJson(old).checklist, isEmpty);
  });
  test(
    'task processing preserves checklist labels and clear removes them',
    () async {
      final job = await create();
      await service.run(job.id);
      final reopened = await SavedWorkService(repository: repository).init();
      expect(reopened.jobs.single.checklist.map((item) => item.label), [
        'Main document',
        'Supporting document',
      ]);
      await reopened.clear();
      expect(reopened.jobs, isEmpty);
      expect(await original.exists(), isTrue);
    },
  );
  test('checklist editing and processing reject concurrent saves', () async {
    final job = await create();
    service.importing.value = true;
    await expectLater(service.updateChecklist(job.id, []), throwsStateError);
    await expectLater(service.run(job.id), throwsStateError);
    service.importing.value = false;
    service.activeId.value = job.id;
    await expectLater(service.updateChecklist(job.id, []), throwsStateError);
    service.activeId.value = null;
  });

  testWidgets(
    'guide sets task operation and editable checklist without invented limits',
    (tester) async {
      Get.testMode = true;
      Get.put<SavedWorkService>(service);
      await tester.pumpWidget(const GetMaterialApp(home: NewSavedWorkView()));
      await tester.tap(find.text('Start with a guide (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Application ZIP').last);
      await tester.pumpAndSettle();
      expect(find.text('Create ZIP'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Application document'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Application document'), findsOneWidget);
      expect(find.text('Supporting document'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit Application document'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Cover letter');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(find.text('Cover letter'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'checklist editor links a file, requires review and resets it on relink',
    (tester) async {
      late SavedJob job;
      await tester.runAsync(() async {
        job = await create();
      });
      var items = job.checklist.take(1).toList();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => SingleChildScrollView(
                child: SubmissionChecklistEditor(
                  items: items,
                  files: job.artifacts,
                  allowLinking: true,
                  onChanged: (next) async => update(() => items = next),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      await tester.tap(find.text('Link saved files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('document.txt'));
      await tester.tap(find.text('Save links'));
      await tester.pumpAndSettle();
      expect(items.single.artifactIds, [job.artifacts.first.id]);
      await tester.tap(find.text('I reviewed the linked document'));
      await tester.pumpAndSettle();
      expect(items.single.reviewed, isTrue);
      await tester.tap(find.text('Link saved files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save links'));
      await tester.pumpAndSettle();
      expect(items.single.reviewed, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
