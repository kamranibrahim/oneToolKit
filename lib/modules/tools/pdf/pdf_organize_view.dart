import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';
import 'pdf_tool_helpers.dart';

class PdfOrganizeView extends StatefulWidget {
  const PdfOrganizeView({super.key});

  @override
  State<PdfOrganizeView> createState() => _PdfOrganizeViewState();
}

class _PdfOrganizeViewState extends State<PdfOrganizeView> {
  PlatformFile? _file;
  final _order = <int>[];
  bool _busy = false;
  String? _status;

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
        _order
          ..clear()
          ..addAll(List.generate(count, (i) => i));
        _status = '$count page(s) — drag to reorder';
      });
    } catch (e) {
      setState(() => _status = 'Failed to open PDF: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final path = _file?.path;
    if (path == null || _order.isEmpty) return;
    setState(() {
      _busy = true;
      _status = 'Reordering…';
    });
    try {
      final source = await PdfToolHelpers.load(path);
      final dest = PdfToolHelpers.rebuildInOrder(source, _order);
      final bytes = await dest.save();
      dest.dispose();
      source.dispose();
      final out = await PdfToolHelpers.writeTempPdf(bytes, 'organized');
      await Share.shareXFiles([XFile(out.path, mimeType: 'application/pdf')]);
      await ToolScaffold.logAction(
        toolId: 'pdf_organize',
        toolName: 'Organize PDF',
        action: 'Reordered',
        detail: '${_order.length} page(s)',
      );
      setState(() => _status = 'Pages reordered');
    } catch (e) {
      setState(() => _status = 'Organize failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_organize',
      title: 'Organize PDF',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Drag pages into a new order, then export a reorganized PDF.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_file == null ? 'Choose PDF' : 'Change PDF'),
                ),
                if (_file != null) ...[
                  const SizedBox(height: 8),
                  Text(_file!.name, style: theme.textTheme.titleSmall),
                ],
              ],
            ),
          ),
          Expanded(
            child: _order.isEmpty
                ? const Center(child: Text('No PDF selected'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _order.length,
                    onReorder: _busy
                        ? (oldIndex, newIndex) {}
                        : (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex -= 1;
                            setState(() {
                              final item = _order.removeAt(oldIndex);
                              _order.insert(newIndex, item);
                            });
                          },
                    itemBuilder: (context, index) {
                      final page = _order[index];
                      return ListTile(
                        key: ValueKey('page-$page-$index'),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text('Original page ${page + 1}'),
                        trailing: const Icon(Icons.drag_handle_rounded),
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
              onPressed: _order.isEmpty || _busy ? null : _save,
              child: Text(_busy ? 'Working…' : 'Save order & share'),
            ),
          ),
        ],
      ),
    );
  }
}
