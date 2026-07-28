import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/share_helper.dart';
import '../../../widgets/tool_scaffold.dart';
import 'pdf_thumbnails.dart';
import 'pdf_tool_helpers.dart';

class PdfOrganizeView extends StatefulWidget {
  const PdfOrganizeView({super.key});

  @override
  State<PdfOrganizeView> createState() => _PdfOrganizeViewState();
}

class _PdfOrganizeViewState extends State<PdfOrganizeView> {
  PlatformFile? _file;
  final _order = <int>[];
  Map<int, Uint8List> _thumbs = {};
  bool _busy = false;
  bool _loadingThumbs = false;
  String? _status;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }
    setState(() {
      _busy = true;
      _loadingThumbs = true;
      _status = 'Reading pages…';
      _thumbs = {};
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
        _status = count > 40
            ? '$count page(s) — first 40 previews loaded'
            : '$count page(s) — drag to reorder';
        _busy = false;
      });

      final thumbs = await PdfThumbnails.render(
        file.path!,
        maxPages: 40,
      );
      if (!mounted) return;
      setState(() {
        _thumbs = thumbs;
        _loadingThumbs = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to open PDF: $e';
        _busy = false;
        _loadingThumbs = false;
      });
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
      if (!mounted) return;
      await shareFiles(context, [XFile(out.path, mimeType: 'application/pdf')]);
      await ToolScaffold.logAction(
        toolId: 'pdf_organize',
        toolName: 'Organize PDF',
        action: 'Reordered',
        detail: '${_order.length} page(s)',
      );
      if (!mounted) return;
      setState(() => _status = 'Pages reordered');
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Organize failed: ${friendlyShareError(e)}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
                  'Drag page previews into a new order, then export.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || _loadingThumbs ? null : _pick,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_file == null ? 'Choose PDF' : 'Change PDF'),
                ),
                if (_file != null) ...[
                  const SizedBox(height: 8),
                  Text(_file!.name, style: theme.textTheme.titleSmall),
                ],
                if (_loadingThumbs) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  Text(
                    'Generating page previews…',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
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
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
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
                      final thumb = _thumbs[page];
                      return Card(
                        key: ValueKey('page-$page'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                          leading: SizedBox(
                            width: 52,
                            height: 68,
                            child: thumb == null
                                ? Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${page + 1}',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      thumb,
                                      fit: BoxFit.cover,
                                      width: 52,
                                      height: 68,
                                    ),
                                  ),
                          ),
                          title: Text('Page ${index + 1}'),
                          subtitle: Text('Was page ${page + 1}'),
                          trailing: const Icon(Icons.drag_handle_rounded),
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
              onPressed: _order.isEmpty || _busy ? null : _save,
              child: Text(_busy ? 'Working…' : 'Save order & share'),
            ),
          ),
        ],
      ),
    );
  }
}
