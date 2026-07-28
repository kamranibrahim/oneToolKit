import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/share_helper.dart';
import '../../../widgets/tool_scaffold.dart';
import 'pdf_thumbnails.dart';
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
  Map<int, Uint8List> _thumbs = {};
  bool _busy = false;
  bool _loadingThumbs = false;
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
        _pageCount = count;
        _selected
          ..clear()
          ..addAll(List.generate(count, (i) => i));
        _range.text = count <= 1 ? '1' : '1-$count';
        _status = '$count page(s) — tap previews to keep or drop';
        _busy = false;
      });

      final thumbs = await PdfThumbnails.render(file.path!, maxPages: 40);
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
      if (!mounted) return;
      setState(() => _status = 'Extracted ${order.length} page(s)');
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Extract failed: ${friendlyShareError(e)}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_extract',
      title: 'Extract Pages',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Keep only the pages you need. Use ranges or tap page previews.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy || _loadingThumbs ? null : _pick,
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
                  if (_loadingThumbs) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${_selected.length} of $_pageCount selected',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pageCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, i) {
                      final selected = _selected.contains(i);
                      final thumb = _thumbs[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _busy
                            ? null
                            : () => setState(() {
                                  if (selected) {
                                    _selected.remove(i);
                                  } else {
                                    _selected.add(i);
                                  }
                                }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (thumb != null)
                                Image.memory(thumb, fit: BoxFit.cover)
                              else
                                ColoredBox(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Center(child: Text('${i + 1}')),
                                ),
                              Positioned(
                                left: 6,
                                top: 6,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: selected
                                      ? theme.colorScheme.primary
                                      : Colors.black54,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed:
                  _file == null || _selected.isEmpty || _busy ? null : _extract,
              child: Text(_busy ? 'Working…' : 'Extract & share'),
            ),
          ),
        ],
      ),
    );
  }
}
