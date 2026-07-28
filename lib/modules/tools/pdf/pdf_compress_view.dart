import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

class PdfCompressView extends StatefulWidget {
  const PdfCompressView({super.key});

  @override
  State<PdfCompressView> createState() => _PdfCompressViewState();
}

class _PdfCompressViewState extends State<PdfCompressView> {
  PlatformFile? _file;
  int _quality = 65;
  int _maxWidth = 1000;
  bool _busy = false;
  String? _status;
  String? _outputPath;
  int? _originalSize;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _file = file;
      _originalSize = File(file.path!).lengthSync();
      _outputPath = null;
      _status = null;
    });
  }

  Future<void> _compress() async {
    if (_file?.path == null) return;
    setState(() {
      _busy = true;
      _status = 'Compressing…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final imgDir = Directory(p.join(dir.path, 'pdf_c_img_$stamp'));
      await imgDir.create(recursive: true);

      final images = await PdfCombiner.createImageFromPDF(
        input: MergeInput.path(_file!.path!),
        outputDirPath: imgDir.path,
        config: ImageFromPdfConfig(
          rescale: ImageScale(width: _maxWidth, height: (_maxWidth * 1.414).round()),
          createOneImage: false,
        ),
      );

      final compressedInputs = <MergeInput>[];
      for (var i = 0; i < images.length; i++) {
        final outJpg = p.join(imgDir.path, 'c_$i.jpg');
        final result = await FlutterImageCompress.compressAndGetFile(
          images[i],
          outJpg,
          quality: _quality,
          format: CompressFormat.jpeg,
        );
        compressedInputs.add(MergeInput.path(result?.path ?? images[i]));
      }

      final outPath = p.join(dir.path, 'compressed_$stamp.pdf');
      final pdfPath = await PdfCombiner.createPDFFromMultipleImages(
        inputs: compressedInputs,
        outputPath: outPath,
      );
      final size = await File(pdfPath).length();

      setState(() {
        _outputPath = pdfPath;
        _status = 'Done · ${_sizeLabel(_originalSize)} → ${_sizeLabel(size)}';
      });
      await ToolScaffold.logAction(
        toolId: 'pdf_compress',
        toolName: 'Compress PDF',
        action: 'Compressed',
        detail: '${_sizeLabel(_originalSize)} → ${_sizeLabel(size)}',
      );
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  String _sizeLabel(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'pdf_compress',
      title: 'Compress PDF',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pages are re-encoded as compressed images and rebuilt into a smaller PDF. Best for scanned documents.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_file?.name ?? 'Choose PDF'),
          ),
          if (_file != null) ...[
            const SizedBox(height: 16),
            Text('Quality: $_quality'),
            Slider(
              value: _quality.toDouble(),
              min: 20,
              max: 90,
              divisions: 14,
              label: '$_quality',
              onChanged: _busy ? null : (v) => setState(() => _quality = v.round()),
            ),
            Text('Max width: $_maxWidth px'),
            Slider(
              value: _maxWidth.toDouble(),
              min: 600,
              max: 1600,
              divisions: 10,
              label: '$_maxWidth',
              onChanged: _busy ? null : (v) => setState(() => _maxWidth = v.round()),
            ),
            FilledButton.tonal(
              onPressed: _busy ? null : _compress,
              child: Text(_busy ? 'Compressing…' : 'Compress'),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_outputPath != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => shareFiles(context, [
                XFile(_outputPath!, mimeType: 'application/pdf'),
              ]),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share compressed PDF'),
            ),
          ],
        ],
      ),
    );
  }
}
