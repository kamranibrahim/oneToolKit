import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

class ImagesToPdfView extends StatefulWidget {
  const ImagesToPdfView({super.key});

  @override
  State<ImagesToPdfView> createState() => _ImagesToPdfViewState();
}

class _ImagesToPdfViewState extends State<ImagesToPdfView> {
  final _picker = ImagePicker();
  final _images = <XFile>[];
  bool _busy = false;

  Future<void> _pick() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() => _images.addAll(files));
  }

  Future<void> _createPdf() async {
    if (_images.isEmpty) return;
    setState(() => _busy = true);
    try {
      final doc = pw.Document();
      for (final file in _images) {
        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        );
      }
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'images_${DateTime.now().millisecondsSinceEpoch}.pdf');
      final out = File(path);
      await out.writeAsBytes(await doc.save());
      if (!mounted) return;
      await shareFiles(context, [XFile(path)]);
      await ToolScaffold.logAction(
        toolId: 'images_to_pdf',
        toolName: 'Images to PDF',
        action: 'Created',
        detail: '${_images.length} pages',
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'images_to_pdf',
      title: 'Images to PDF',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Add images'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _images.isEmpty || _busy ? null : _createPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(_busy ? 'Creating…' : 'Create PDF'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('No images selected'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _images.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = _images.removeAt(oldIndex);
                        _images.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final file = _images[index];
                      return ListTile(
                        key: ValueKey(file.path),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(file.path),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text('Page ${index + 1}'),
                        subtitle: Text(p.basename(file.path), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _images.removeAt(index)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
