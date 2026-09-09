import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';
import '../../../data/models/shared_file.dart';
import '../../../data/services/pending_share_service.dart';

import '../../../widgets/tool_scaffold.dart';

class PdfMergeView extends StatefulWidget {
  const PdfMergeView({super.key});

  @override
  State<PdfMergeView> createState() => _PdfMergeViewState();
}

class _PdfMergeViewState extends State<PdfMergeView> {
  final _files = <PlatformFile>[];
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    final share = Get.isRegistered<PendingShareService>()
        ? Get.find<PendingShareService>()
        : null;
    final files = share?.takeFor('pdf_merge') ?? const <SharedFile>[];
    if (files.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final added = <PlatformFile>[];
        for (final f in files) {
          final file = File(f.path);
          if (!file.existsSync()) continue;
          added.add(
            PlatformFile(
              name: p.basename(f.path),
              path: f.path,
              size: file.lengthSync(),
            ),
          );
        }
        if (added.isEmpty) return;
        setState(() {
          _files.addAll(added);
          _status = null;
        });
      });
    }
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;
    setState(() {
      _files.addAll(result.files.where((f) => f.path != null));
      _status = null;
    });
  }

  Future<void> _merge() async {
    if (_files.length < 2) {
      ToolScaffold.copy('', message: 'Select at least 2 PDFs');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Merging…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      final inputs = _files
          .where((f) => f.path != null)
          .map((f) => MergeInput.path(f.path!))
          .toList();

      final resultPath = await PdfCombiner.mergeMultiplePDFs(
        inputs: inputs,
        outputPath: outPath,
      );

      if (!mounted) return;
      await shareFiles(context, [XFile(resultPath, mimeType: 'application/pdf')]);
      await ToolScaffold.logAction(
        toolId: 'pdf_merge',
        toolName: 'Merge PDF',
        action: 'Merged',
        detail: '${_files.length} files',
      );
      if (!mounted) return;
      setState(() => _status = 'Merged ${_files.length} PDFs');
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Merge failed: ${friendlyShareError(e)}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_merge',
      title: 'Merge PDF',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select PDFs, drag to reorder, then merge into one file — entirely on device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Add PDFs'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _files.isEmpty
                ? const Center(child: Text('No PDFs selected'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _files.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = _files.removeAt(oldIndex);
                        _files.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      return ListTile(
                        key: ValueKey('${file.path}-$index'),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.error.withValues(alpha: 0.12),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_sizeLabel(file.size)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _busy
                              ? null
                              : () => setState(() => _files.removeAt(index)),
                        ),
                      );
                    },
                  ),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_status!, textAlign: TextAlign.center),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _files.length < 2 || _busy ? null : _merge,
              child: Text(_busy ? 'Merging…' : 'Merge & share'),
            ),
          ),
        ],
      ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
