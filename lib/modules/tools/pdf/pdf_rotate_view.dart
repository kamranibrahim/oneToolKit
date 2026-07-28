import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../widgets/tool_scaffold.dart';

class PdfRotateView extends StatefulWidget {
  const PdfRotateView({super.key});

  @override
  State<PdfRotateView> createState() => _PdfRotateViewState();
}

class _PdfRotateViewState extends State<PdfRotateView> {
  PlatformFile? _file;
  int _degrees = 90;
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _file = result.files.first;
      _status = null;
    });
  }

  PdfPageRotateAngle _angleFor(PdfPageRotateAngle current) {
    final steps = _degrees ~/ 90;
    final values = PdfPageRotateAngle.values;
    final next = (current.index + steps) % values.length;
    return values[next];
  }

  Future<void> _rotate() async {
    final file = _file;
    final path = file?.path;
    if (file == null || path == null) {
      ToolScaffold.copy('', message: 'Select a PDF first');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Rotating…';
    });
    try {
      final bytes = await File(path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      for (var i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        page.rotation = _angleFor(page.rotation);
      }
      final outBytes = await document.save();
      final pageCount = document.pages.count;
      document.dispose();

      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        'rotated_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(outPath).writeAsBytes(outBytes, flush: true);
      await Share.shareXFiles([
        XFile(outPath, mimeType: 'application/pdf'),
      ]);
      await ToolScaffold.logAction(
        toolId: 'pdf_rotate',
        toolName: 'Rotate PDF',
        action: 'Rotated $_degrees°',
        detail: '$pageCount page(s)',
      );
      setState(() => _status = 'Rotated $pageCount page(s) by $_degrees°');
    } catch (e) {
      setState(() => _status = 'Rotate failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_rotate',
      title: 'Rotate PDF',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rotate every page by 90°, 180°, or 270° — offline, on device.',
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.rotate_right_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(_file!.name),
              subtitle: Text(_sizeLabel(_file!.size)),
            ),
          ],
          const SizedBox(height: 8),
          Text('Rotation', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 90, label: Text('90°')),
              ButtonSegment(value: 180, label: Text('180°')),
              ButtonSegment(value: 270, label: Text('270°')),
            ],
            selected: {_degrees},
            onSelectionChanged: _busy
                ? null
                : (s) => setState(() => _degrees = s.first),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _file == null || _busy ? null : _rotate,
            child: Text(_busy ? 'Rotating…' : 'Rotate & share'),
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
