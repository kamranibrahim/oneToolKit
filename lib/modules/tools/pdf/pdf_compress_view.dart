import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/processing/pdf_compression.dart';
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
  bool _scannedCopy = false;
  bool _reduced = false;
  bool _busy = false;
  String? _status;
  String? _outputPath;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (!mounted ||
        result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _file = file;
      _outputPath = null;
      _status = null;
    });
  }

  Future<void> _compress() async {
    if (_file?.path == null) return;
    final path = _file!.path!;
    final scanned = _scannedCopy;
    final quality = _quality;
    setState(() {
      _busy = true;
      _outputPath = null;
      _status = 'Compressing…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final result = await PdfCompression.optimize(
        path,
        dir.path,
        scannedCopy: scanned,
        quality: quality,
      );
      if (!mounted) return;
      setState(() {
        _outputPath = result.path;
        _reduced = result.reduced;
        _status = result.reduced
            ? 'Size checked · ${_sizeLabel(result.originalBytes)} → ${_sizeLabel(result.outputBytes)}'
            : 'No smaller copy found. Original retained (${_sizeLabel(result.originalBytes)}).';
      });
      if (result.reduced) {
        await ToolScaffold.logAction(
          toolId: 'pdf_compress',
          toolName: 'Compress PDF',
          action: 'Compressed',
          detail:
              '${_sizeLabel(result.originalBytes)} → ${_sizeLabel(result.outputBytes)}',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final path = _outputPath;
    if (path == null || _busy) return;
    try {
      await shareFiles(context, [XFile(path, mimeType: 'application/pdf')]);
    } catch (e) {
      if (mounted) setState(() => _status = 'Share failed: $e');
    }
  }

  void _invalidate() {
    _outputPath = null;
    _status = null;
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
            'Preserve mode keeps text and page layout. Already optimized PDFs may not become smaller. Review the exported copy before use.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Create a scanned-image copy'),
              subtitle: const Text(
                'Optional: removes selectable text, links and other interactive content. Best for scans. Originals stay unchanged.',
              ),
              value: _scannedCopy,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _scannedCopy = value;
                      _invalidate();
                    }),
            ),
            if (_scannedCopy) ...[
              Text('Quality: $_quality'),
              Slider(
                value: _quality.toDouble(),
                min: 20,
                max: 90,
                divisions: 14,
                label: '$_quality',
                onChanged: _busy
                    ? null
                    : (v) => setState(() {
                        _quality = v.round();
                        _invalidate();
                      }),
              ),
            ],
            FilledButton.tonal(
              onPressed: _busy ? null : _compress,
              child: Text(_busy ? 'Compressing…' : 'Compress'),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_outputPath != null && !_busy) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(
                _reduced ? 'Share compressed PDF' : 'Share original PDF',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
