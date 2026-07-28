import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

class PdfSplitView extends StatefulWidget {
  const PdfSplitView({super.key});

  @override
  State<PdfSplitView> createState() => _PdfSplitViewState();
}

class _PdfSplitViewState extends State<PdfSplitView> {
  PlatformFile? _file;
  List<String> _pagePdfs = [];
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _file = result.files.first;
      _pagePdfs = [];
      _status = null;
    });
  }

  Future<void> _split() async {
    if (_file?.path == null) return;
    setState(() {
      _busy = true;
      _status = 'Splitting pages…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final imgDir = Directory(p.join(dir.path, 'split_img_$stamp'));
      await imgDir.create(recursive: true);

      final images = await PdfCombiner.createImageFromPDF(
        input: MergeInput.path(_file!.path!),
        outputDirPath: imgDir.path,
        config: const ImageFromPdfConfig(
          rescale: ImageScale(width: 1240, height: 1754),
          createOneImage: false,
        ),
      );

      final outDir = Directory(p.join(dir.path, 'split_pdf_$stamp'));
      await outDir.create(recursive: true);
      final outputs = <String>[];

      for (var i = 0; i < images.length; i++) {
        final outPath = p.join(outDir.path, 'page_${i + 1}.pdf');
        final pdfPath = await PdfCombiner.createPDFFromMultipleImages(
          inputs: [MergeInput.path(images[i])],
          outputPath: outPath,
        );
        outputs.add(pdfPath);
      }

      setState(() {
        _pagePdfs = outputs;
        _status = 'Split into ${outputs.length} PDF(s)';
      });
      await ToolScaffold.logAction(
        toolId: 'pdf_split',
        toolName: 'Split PDF',
        action: 'Split',
        detail: '${outputs.length} pages',
      );
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _shareAll() async {
    if (_pagePdfs.isEmpty) return;
    if (!mounted) return;
    await shareFiles(context, 
      _pagePdfs.map((path) => XFile(path, mimeType: 'application/pdf')).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'pdf_split',
      title: 'Split PDF',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Each page becomes its own PDF file — processed locally on your device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_file?.name ?? 'Choose PDF'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _file == null || _busy ? null : _split,
                  child: Text(_busy ? 'Splitting…' : 'Split into pages'),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          Expanded(
            child: _pagePdfs.isEmpty
                ? const Center(child: Text('Split pages appear here'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _pagePdfs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text('Page ${index + 1}'),
                          subtitle: Text(p.basename(_pagePdfs[index])),
                          trailing: IconButton(
                            icon: const Icon(Icons.ios_share_rounded),
                            onPressed: () => shareFiles(context, [
                              XFile(_pagePdfs[index], mimeType: 'application/pdf'),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_pagePdfs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _shareAll,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share all pages'),
              ),
            ),
        ],
      ),
    );
  }
}
