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

class PdfToImagesView extends StatefulWidget {
  const PdfToImagesView({super.key});

  @override
  State<PdfToImagesView> createState() => _PdfToImagesViewState();
}

class _PdfToImagesViewState extends State<PdfToImagesView> {
  PlatformFile? _file;
  List<String> _images = [];
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _file = result.files.first;
      _images = [];
      _status = null;
    });
  }

  Future<void> _convert() async {
    if (_file?.path == null) return;
    setState(() {
      _busy = true;
      _status = 'Converting pages…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final outDir = Directory(
        p.join(dir.path, 'pdf_pages_${DateTime.now().millisecondsSinceEpoch}'),
      );
      await outDir.create(recursive: true);

      final paths = await PdfCombiner.createImageFromPDF(
        input: MergeInput.path(_file!.path!),
        outputDirPath: outDir.path,
        config: const ImageFromPdfConfig(
          rescale: ImageScale(width: 1080, height: 1920),
          createOneImage: false,
        ),
      );

      setState(() {
        _images = paths;
        _status = '${paths.length} page(s) exported';
      });

      await ToolScaffold.logAction(
        toolId: 'pdf_to_images',
        toolName: 'PDF to Images',
        action: 'Exported',
        detail: '${paths.length} pages',
      );
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _shareAll() async {
    if (_images.isEmpty) return;
    if (!mounted) return;
    await shareFiles(context, _images.map(XFile.new).toList());
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'pdf_to_images',
      title: 'PDF to Images',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_file?.name ?? 'Choose PDF'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _file == null || _busy ? null : _convert,
                  child: Text(_busy ? 'Converting…' : 'Export pages'),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('Page previews appear here'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_images[index]),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _shareAll,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share images'),
              ),
            ),
        ],
      ),
    );
  }
}
