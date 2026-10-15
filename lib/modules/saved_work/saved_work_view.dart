import 'instruction_review_view.dart';
import '../../data/saved_work/instruction_proposals.dart';
import 'submission_checklist_editor.dart';
import '../../data/saved_work/submission_checklist.dart';
import '../../data/saved_work/submission_preset.dart';
import 'package:uuid/uuid.dart';
import '../../data/saved_work/submission_requirements.dart';
import '../../data/saved_work/saved_routine.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/share_helper.dart';
import '../../data/processing/file_names.dart';
import '../../data/saved_work/saved_job.dart';
import '../../data/saved_work/saved_work_repository.dart';
import '../../data/services/saved_work_service.dart';

class SavedWorkView extends StatelessWidget {
  const SavedWorkView({super.key});
  @override
  Widget build(BuildContext context) {
    final service = Get.find<SavedWorkService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved work')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const NewSavedWorkView()),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            const Text(
              'Files you choose are copied into private app storage and kept until you delete this work. No cloud backup. Unfinished tasks resume from completed steps.',
            ),
            if (service.storageError.value != null) ...[
              Text(service.storageError.value!),
              TextButton(
                onPressed: service.activeId.value == null
                    ? () => service.init()
                    : null,
                child: const Text('Try opening again'),
              ),
            ],
            for (final warning in service.warnings) Text(warning),
            if (service.jobs.isEmpty && service.ready)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No saved work yet. Create a task to keep its files and results together.',
                ),
              ),
            if (service.routines.isNotEmpty)
              const Text(
                'Reusable routines · settings only, choose fresh files each time',
              ),
            for (final routine in service.routines)
              ListTile(
                title: Text(routine.title),
                leading: const Icon(Icons.repeat),
                onTap: () => Get.to(() => NewSavedWorkView(routine: routine)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete routine',
                  onPressed: () async {
                    try {
                      await service.deleteRoutine(routine.id);
                    } catch (e) {
                      Get.snackbar('Could not delete routine', '$e');
                    }
                  },
                ),
              ),
            for (final job in service.jobs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  job.status == SavedJobStatus.completed
                      ? Icons.task_alt
                      : Icons.folder_outlined,
                ),
                title: Text(job.title),
                subtitle: Text(
                  '${_status(job.status)} · ${job.nextStep}/${job.steps.length} steps',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(() => SavedJobView(id: job.id)),
              ),
          ],
        ),
      ),
    );
  }
}

String _status(SavedJobStatus status) => switch (status) {
  SavedJobStatus.queued => 'Ready',
  SavedJobStatus.running => 'Running',
  SavedJobStatus.paused => 'Paused',
  SavedJobStatus.failed => 'Needs attention',
  SavedJobStatus.completed => 'Completed',
};

class NewSavedWorkView extends StatefulWidget {
  const NewSavedWorkView({super.key, this.routine});
  final SavedRoutine? routine;
  @override
  State<NewSavedWorkView> createState() => _NewSavedWorkViewState();
}

class _NewSavedWorkViewState extends State<NewSavedWorkView> {
  final _title = TextEditingController(text: 'My documents');
  final _name = TextEditingController(text: 'prepared');
  final _size = TextEditingController();
  final _pages = TextEditingController();
  final _exactName = TextEditingController();
  String? _format;
  List<SubmissionChecklistItem> _checklist = [];
  SubmissionPreset? _preset;
  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    if (routine != null) {
      _checklist = routine.checklist.map((item) => item.fresh).toList();
      _title.text = routine.title;
      _name.text = routine.steps.first.outputName;
      _operation = routine.steps.first.operation;
      _size.text = routine.requirements.maxBytes?.toString() ?? '';
      _pages.text = routine.requirements.maxPages?.toString() ?? '';
      _exactName.text = routine.requirements.exactName ?? '';
      _format = routine.requirements.format;
    }
  }

  Future<void> _readInstructions() async {
    final selection = await Navigator.of(context).push<InstructionSelection>(
      MaterialPageRoute(builder: (_) => const InstructionReviewView()),
    );
    if (selection == null || !mounted) return;
    final existing = _checklist.map((item) => item.label.toLowerCase()).toSet();
    final labels = selection.documents
        .where((label) => existing.add(label.toLowerCase()))
        .toList();
    if (_checklist.length + labels.length > 30) {
      setState(
        () => _error =
            'The selected documents would exceed the 30-item checklist limit. No suggestions were applied.',
      );
      return;
    }
    setState(() {
      final rules = selection.requirements;
      if (rules.maxBytes != null) _size.text = rules.maxBytes.toString();
      if (rules.maxPages != null) _pages.text = rules.maxPages.toString();
      if (rules.exactName != null) _exactName.text = rules.exactName!;
      if (rules.format != null) _format = rules.format;
      _checklist = [
        ..._checklist,
        for (final label in labels)
          SubmissionChecklistItem(id: const Uuid().v4(), label: label),
      ];
      _error = null;
    });
  }

  SubmissionRequirements _requirements() {
    int? number(TextEditingController c) {
      if (c.text.trim().isEmpty) return null;
      final n = int.tryParse(c.text.trim());
      if (n == null) {
        throw const FormatException('Limits must be whole numbers.');
      }
      return n;
    }

    return SubmissionRequirements(
      maxBytes: number(_size),
      maxPages: number(_pages),
      format: _format,
      exactName: _exactName.text.trim().isEmpty ? null : _exactName.text.trim(),
    );
  }

  SavedOperation _operation = SavedOperation.imagesToPdf;
  List<SavedImport> _inputs = [];
  bool _package = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _size.dispose();
    _pages.dispose();
    _exactName.dispose();
    _title.dispose();
    _name.dispose();
    super.dispose();
  }

  List<SavedStep> _steps() {
    if (widget.routine != null) return widget.routine!.steps;
    final stem = _name.text.trim().replaceFirst(
      RegExp(r'\.(pdf|zip)$', caseSensitive: false),
      '',
    );
    FileNames.validate(stem);
    return [
      SavedStep(
        _operation,
        '$stem${_operation == SavedOperation.zip ? '.zip' : '.pdf'}',
      ),
      if (_package && _operation != SavedOperation.zip)
        SavedStep(SavedOperation.zip, '$stem.zip'),
    ];
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _operation == SavedOperation.imagesToPdf
            ? ['jpg', 'jpeg', 'png']
            : _operation == SavedOperation.zip
            ? ['pdf', 'jpg', 'jpeg', 'png', 'txt', 'csv']
            : ['pdf'],
      );
      if (!mounted || result == null) return;
      final selected = <SavedImport>[];
      for (final file in result.files) {
        if (file.path == null) {
          throw const FormatException('A selected file could not be opened.');
        }
        final mime = switch (p.extension(file.name).toLowerCase()) {
          '.pdf' => 'application/pdf',
          '.png' => 'image/png',
          '.jpg' || '.jpeg' => 'image/jpeg',
          '.txt' => 'text/plain',
          '.csv' => 'text/csv',
          _ => 'application/octet-stream',
        };
        selected.add(SavedImport(file.path!, file.name, mime));
      }
      setState(() => _inputs = selected);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = Get.find<SavedWorkService>();
      final job = await service.create(
        _title.text,
        _inputs,
        _steps(),
        requirements: _requirements(),
        checklist: _checklist,
      );
      if (!mounted) return;
      Get.off(() => SavedJobView(id: job.id));
      unawaited(service.run(job.id));
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e
              .toString()
              .replaceFirst('FormatException: ', '')
              .replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New saved task')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _readInstructions,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Read submission instructions'),
        ),
        if (widget.routine == null) ...[
          DropdownButtonFormField<SubmissionPreset>(
            initialValue: _preset,
            decoration: const InputDecoration(
              labelText: 'Start with a guide (optional)',
              helperText:
                  'Choosing a guide replaces task settings and file selection.',
            ),
            items: [
              for (final preset in SubmissionPreset.values)
                DropdownMenuItem(value: preset, child: Text(preset.title)),
            ],
            onChanged: _busy
                ? null
                : (preset) {
                    if (preset == null) return;
                    setState(() {
                      _preset = preset;
                      _title.text = preset.title;
                      _name.text = preset.outputStem;
                      _operation = preset.operation;
                      _package = false;
                      _inputs = [];
                      _checklist = [
                        for (final label in preset.documents)
                          SubmissionChecklistItem(
                            id: const Uuid().v4(),
                            label: label,
                          ),
                      ];
                      _error = null;
                    });
                  },
          ),
          if (_preset != null) Text(_preset!.description),
          const Text(
            'Starting points only. Match the checklist and export rules to the instructions you received.',
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _title,
          enabled: !_busy,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Task name'),
        ),
        DropdownButtonFormField<SavedOperation>(
          key: ValueKey(_operation),
          initialValue: _operation,
          decoration: const InputDecoration(
            labelText: 'What would you like to do?',
          ),
          items: [
            for (final op in SavedOperation.values)
              DropdownMenuItem(value: op, child: Text(op.label)),
          ],
          onChanged: _busy || widget.routine != null
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _operation = value;
                      _inputs = [];
                      _error = null;
                    });
                  }
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          enabled: !_busy && widget.routine == null,
          decoration: const InputDecoration(
            labelText: 'Result filename',
            helperText: 'The PDF or ZIP extension is added automatically.',
          ),
        ),
        if (_operation != SavedOperation.zip && widget.routine == null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Package result as ZIP'),
            value: _package,
            onChanged: _busy
                ? null
                : (value) => setState(() => _package = value),
          ),
        SubmissionChecklistEditor(
          items: _checklist,
          enabled: !_busy,
          onChanged: (items) async => setState(() => _checklist = items),
        ),
        ExpansionTile(
          title: const Text('Submission requirements (optional)'),
          subtitle: const Text(
            'Rules apply to the final export. Empty fields are not checked.',
          ),
          children: [
            TextField(
              controller: _size,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum file size in bytes',
              ),
            ),
            TextField(
              controller: _pages,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum PDF pages (1–100)',
              ),
            ),
            TextField(
              controller: _exactName,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Required full filename including extension',
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey(_format ?? 'any'),
              initialValue: _format ?? 'any',
              decoration: const InputDecoration(
                labelText: 'Required export format',
              ),
              items: const [
                DropdownMenuItem(value: 'any', child: Text('No format rule')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'zip', child: Text('ZIP')),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _format = v == 'any' ? null : v),
            ),
          ],
        ),
        if (widget.routine != null)
          Text(
            'Routine steps: ${widget.routine!.steps.map((s) => s.outputName).join(' → ')}',
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.attach_file),
          label: const Text('Choose files'),
        ),
        const Text(
          'Files are processed in this order. Use the arrows to change it before saving.',
        ),
        for (var i = 0; i < _inputs.length; i++)
          ListTile(
            title: Text(_inputs[i].name),
            leading: Text('${i + 1}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Move up',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _busy || i == 0
                      ? null
                      : () => setState(() {
                          final item = _inputs.removeAt(i);
                          _inputs.insert(i - 1, item);
                        }),
                ),
                IconButton(
                  tooltip: 'Remove file',
                  icon: const Icon(Icons.close),
                  onPressed: _busy
                      ? null
                      : () => setState(() => _inputs.removeAt(i)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          _package && _operation != SavedOperation.zip
              ? '${_operation.label} → Create ZIP'
              : _operation.label,
        ),
        const Text(
          'Up to 100 MB per task and 500 MB of saved work. PDF merge supports up to 100 pages without forms. Images to PDF supports up to 20 JPG/PNG images.',
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Obx(() {
          final service = Get.find<SavedWorkService>();
          final available =
              service.activeId.value == null &&
              service.ready &&
              !service.importing.value;
          return FilledButton(
            onPressed: _busy || _inputs.isEmpty || !available ? null : _create,
            child: const Text('Save and run task'),
          );
        }),
      ],
    ),
  );
}

class SavedJobView extends StatelessWidget {
  const SavedJobView({super.key, required this.id});
  final String id;
  Future<void> _action(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      Get.snackbar(
        'Could not complete action',
        e.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  Widget _fileTile(
    BuildContext context,
    SavedWorkService service,
    SavedJob job,
    SavedArtifact file,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(file.name),
    subtitle: Text('${(file.bytes / 1024).toStringAsFixed(1)} KB'),
    trailing: Wrap(
      children: [
        if (file.mime == 'application/pdf' || file.mime.startsWith('image/'))
          IconButton(
            tooltip: 'Preview ${file.name}',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => _action(() async {
              await service.repository.verify(job, file);
              if (!context.mounted) return;
              final path = service.repository.filePath(job, file);
              if (file.mime == 'application/pdf') {
                final bytes = await File(path).readAsBytes();
                if (!context.mounted) return;
                Get.to(
                  () => Scaffold(
                    appBar: AppBar(title: Text(file.name)),
                    body: PdfPreview(
                      build: (_) async => bytes,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                    ),
                  ),
                );
              } else {
                Get.to(
                  () => Scaffold(
                    appBar: AppBar(title: Text(file.name)),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.file(
                          File(path),
                          cacheWidth: 1600,
                          errorBuilder: (_, error, stack) =>
                              const Text('This image could not be previewed.'),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }),
          ),
        IconButton(
          tooltip: 'Share ${file.name}',
          icon: const Icon(Icons.ios_share),
          onPressed: () => _action(() async {
            await service.repository.verify(job, file);
            if (!context.mounted) return;
            await shareFiles(context, [
              XFile(
                service.repository.filePath(job, file),
                mimeType: file.mime,
              ),
            ]);
          }),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final service = Get.find<SavedWorkService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved task')),
      body: Obx(() {
        final job = service.find(id);
        if (job == null) {
          return const Center(child: Text('This work is no longer saved.'));
        }
        final active = service.activeId.value == id;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              '${_status(job.status)} · ${job.nextStep}/${job.steps.length} steps completed',
            ),
            for (var i = 0; i < job.steps.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  i < job.nextStep
                      ? Icons.check_circle_outline
                      : Icons.circle_outlined,
                ),
                title: Text(job.steps[i].operation.label),
                subtitle: Text(job.steps[i].outputName),
              ),
            if (job.message != null) Text(job.message!),
            const SizedBox(height: 16),
            SubmissionChecklistEditor(
              key: ValueKey(job.id),
              items: job.checklist,
              files: job.artifacts,
              allowLinking: true,
              enabled:
                  service.activeId.value == null && !service.importing.value,
              onChanged: (items) => service.updateChecklist(id, items),
            ),
            if (active) ...[
              const LinearProgressIndicator(),
              TextButton(
                onPressed: service.pauseRequested.value ? null : service.pause,
                child: Text(
                  service.pauseRequested.value
                      ? 'Pausing after this step…'
                      : 'Pause after this step',
                ),
              ),
            ] else if (job.status != SavedJobStatus.completed)
              FilledButton(
                onPressed: service.activeId.value == null
                    ? () => _action(() => service.run(id))
                    : null,
                child: Text(
                  job.nextStep == 0 && job.status == SavedJobStatus.queued
                      ? 'Start task'
                      : 'Resume task',
                ),
              ),
            if (job.status == SavedJobStatus.completed) ...[
              Text(
                job.requirements.isEmpty && job.checklist.isEmpty
                    ? 'No submission rules set for this task.'
                    : 'Processing is complete. Submission requirements still need checking.',
              ),
              if (!job.requirements.isEmpty || job.checklist.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Check submission requirements'),
                  onPressed: () => _action(() async {
                    final checks = await service.checkSubmission(id);
                    if (!context.mounted) return;
                    final passed =
                        checks.isNotEmpty &&
                        checks.every(
                          (c) => c.status == SubmissionCheckStatus.passed,
                        );
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          passed
                              ? 'Measured rules passed'
                              : 'Requirements need attention',
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final check in checks)
                                Text(
                                  '${switch (check.status) {
                                    SubmissionCheckStatus.passed => 'Passed',
                                    SubmissionCheckStatus.failed => 'Failed',
                                    SubmissionCheckStatus.unresolved => 'Unresolved',
                                  }}: ${check.message}',
                                ),
                              const SizedBox(height: 12),
                              const Text(
                                'Review readability, document contents and the destination’s latest instructions before submitting. These checks do not guarantee acceptance.',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
            ],
            TextButton.icon(
              icon: const Icon(Icons.repeat),
              label: const Text('Save settings as a routine'),
              onPressed: () => _action(() async {
                await service.saveRoutine(job);
                Get.snackbar(
                  'Routine saved',
                  'Choose fresh files from Saved work to use it again.',
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              job.status == SavedJobStatus.completed
                  ? 'Results'
                  : 'Saved files',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final file
                in (job.status == SavedJobStatus.completed
                    ? job.artifacts
                          .where((file) => file.sourceIds.isNotEmpty)
                          .toList()
                    : job.currentFiles))
              _fileTile(context, service, job, file),
            if (job.status == SavedJobStatus.completed)
              ExpansionTile(
                title: const Text('Original imports'),
                children: [
                  for (final file in job.artifacts.where(
                    (file) => file.sourceIds.isEmpty,
                  ))
                    _fileTile(context, service, job, file),
                ],
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete saved task and its files'),
              onPressed: active || service.importing.value
                  ? null
                  : () => _action(() async {
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Delete saved task?'),
                          content: const Text(
                            'Deletes the app’s saved copies and results. Files outside OneToolkit remain unchanged.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Keep'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await service.delete(id);
                        Get.back();
                      }
                    }),
            ),
          ],
        );
      }),
    );
  }
}
