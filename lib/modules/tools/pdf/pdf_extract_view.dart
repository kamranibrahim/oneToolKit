import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';
import 'pdf_tool_helpers.dart';

class PdfExtractView extends StatefulWidget {
  const PdfExtractView({super.key});

  @override
  State<PdfExtractView> createState() => _PdfExtractViewState();
}

class _PdfExtractViewState extends State<PdfExtractView> {
  PlatformFile? _file;
  int _pageCount = 0;
  final _range = TextEditingController();
  final _selected = <int>{};
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
        _selected
          ..clear()
          ..addAll(List.generate(count, (i) => i));
        _range.text = count <= 1 ? '1' : '1-$count';
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
      _selected
        ..clear()
        ..addAll(PdfToolHelpers.parsePageSelection(_range.text, _pageCount));
    });
  }

  Future<void> _extract() async {
    final path = _file?.path;
    if (path == null || _selected.isEmpty) {
      ToolScaffold.copy('', message: 'Select at least one page');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Extracting…';
    });
    try {
      final source = await PdfToolHelpers.load(path);
      final order = _selected.toList()..sort();
      final dest = PdfToolHelpers.rebuildInOrder(source, order);
      final bytes = await dest.save();
      dest.dispose();
      source.dispose();
      final out = await PdfToolHelpers.writeTempPdf(bytes, 'extracted');
      if (!mounted) return;
      await shareFiles(context, [XFile(out.path, mimeType: 'application/pdf')]);
      await ToolScaffold.logAction(
        toolId: 'pdf_extract',
        toolName: 'Extract Pages',
        action: 'Extracted',
        detail: '${order.length} of $_pageCount',
      );
      setState(() => _status = 'Extracted ${order.length} page(s)');
    } catch (e) {
      setState(() => _status = 'Extract failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_extract',
      title: 'Extract Pages',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Keep only the pages you need. Use ranges like 1-3,5 or tap pages below.',
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
                labelText: 'Pages (1–$_pageCount)',
                hintText: '1-3,5',
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
                final selected = _selected.contains(i);
                return FilterChip(
                  label: Text('${i + 1}'),
                  selected: selected,
                  onSelected: _busy
                      ? null
                      : (v) => setState(() {
                            if (v) {
                              _selected.add(i);
                            } else {
                              _selected.remove(i);
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
            onPressed: _file == null || _selected.isEmpty || _busy ? null : _extract,
            child: Text(_busy ? 'Working…' : 'Extract & share'),
          ),
        ],
      ),
    );
  }
}
