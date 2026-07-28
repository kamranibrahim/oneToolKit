import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';
import 'pdf_tool_helpers.dart';

class PdfDeletePagesView extends StatefulWidget {
  const PdfDeletePagesView({super.key});

  @override
  State<PdfDeletePagesView> createState() => _PdfDeletePagesViewState();
}

class _PdfDeletePagesViewState extends State<PdfDeletePagesView> {
  PlatformFile? _file;
  int _pageCount = 0;
  final _range = TextEditingController();
  final _toDelete = <int>{};
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _range.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Reading pages…';
    });
    try {
      final file = result.files.first;
      final doc = await PdfToolHelpers.load(file.path!);
      final count = doc.pages.count;
      doc.dispose();
      setState(() {
        _file = file;
        _pageCount = count;
        _toDelete.clear();
        _range.clear();
        _status = '$count page(s)';
      });
    } catch (e) {
      setState(() => _status = 'Failed to open PDF: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _applyRange() {
    if (_pageCount == 0) return;
    setState(() {
      _toDelete
        ..clear()
        ..addAll(PdfToolHelpers.parsePageSelection(_range.text, _pageCount));
    });
  }

  Future<void> _delete() async {
    final path = _file?.path;
    if (path == null || _toDelete.isEmpty) {
      ToolScaffold.copy('', message: 'Select pages to delete');
      return;
    }
    if (_toDelete.length >= _pageCount) {
      ToolScaffold.copy('', message: 'Keep at least one page');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Deleting…';
    });
    try {
      final source = await PdfToolHelpers.load(path);
      final keep = [
        for (var i = 0; i < source.pages.count; i++)
          if (!_toDelete.contains(i)) i,
      ];
      final dest = PdfToolHelpers.rebuildInOrder(source, keep);
      final bytes = await dest.save();
      dest.dispose();
      source.dispose();
      final out = await PdfToolHelpers.writeTempPdf(bytes, 'trimmed');
      await Share.shareXFiles([XFile(out.path, mimeType: 'application/pdf')]);
      await ToolScaffold.logAction(
        toolId: 'pdf_delete_pages',
        toolName: 'Delete Pages',
        action: 'Deleted',
        detail: '${_toDelete.length} page(s)',
      );
      setState(() => _status = 'Removed ${_toDelete.length} page(s)');
    } catch (e) {
      setState(() => _status = 'Delete failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_delete_pages',
      title: 'Delete Pages',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Remove unwanted pages. The original file is left untouched.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_file == null ? 'Choose PDF' : 'Change PDF'),
          ),
          if (_file != null) ...[
            const SizedBox(height: 12),
            Text(_file!.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _range,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Pages to delete (1–$_pageCount)',
                hintText: '2,4-6',
                suffixIcon: TextButton(
                  onPressed: _busy ? null : _applyRange,
                  child: const Text('Apply'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_pageCount, (i) {
                final marked = _toDelete.contains(i);
                return FilterChip(
                  label: Text('${i + 1}'),
                  selected: marked,
                  selectedColor: theme.colorScheme.error.withValues(alpha: 0.2),
                  checkmarkColor: theme.colorScheme.error,
                  onSelected: _busy
                      ? null
                      : (v) => setState(() {
                            if (v) {
                              _toDelete.add(i);
                            } else {
                              _toDelete.remove(i);
                            }
                          }),
                );
              }),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                _file == null || _toDelete.isEmpty || _busy ? null : _delete,
            child: Text(_busy ? 'Working…' : 'Delete & share'),
          ),
        ],
      ),
    );
  }
}
