import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

class ImageCompressView extends StatefulWidget {
  const ImageCompressView({super.key});

  @override
  State<ImageCompressView> createState() => _ImageCompressViewState();
}

class _ImageCompressViewState extends State<ImageCompressView> {
  final _picker = ImagePicker();
  XFile? _original;
  Uint8List? _compressed;
  int _quality = 70;
  int? _originalSize;
  int? _compressedSize;
  bool _busy = false;

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _original = file;
      _originalSize = bytes.length;
      _compressed = null;
      _compressedSize = null;
    });
    await _compress();
  }

  Future<void> _compress() async {
    if (_original == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _original!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Unsupported image');
      final encoded = img.encodeJpg(decoded, quality: _quality);
      setState(() {
        _compressed = Uint8List.fromList(encoded);
        _compressedSize = encoded.length;
      });
    } catch (e) {
      ToolScaffold.copy('', message: 'Compress failed');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_compressed == null) return;
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(path).writeAsBytes(_compressed!);
    if (!mounted) return;
    await shareFiles(context, [XFile(path)]);
    await ToolScaffold.logAction(
      toolId: 'image_compress',
      toolName: 'Compress Image',
      action: 'Compressed',
      detail: '${_formatSize(_originalSize)} → ${_formatSize(_compressedSize)}',
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'image_compress',
      title: 'Compress Image',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose image'),
          ),
          if (_original != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_original!.path), height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text('Quality: $_quality'),
            Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 95,
              divisions: 17,
              label: '$_quality',
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _quality = v.round()),
              onChangeEnd: (_) => _compress(),
            ),
            Text('Original: ${_formatSize(_originalSize)}'),
            Text('Compressed: ${_formatSize(_compressedSize)}'),
            if (_busy) const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _compressed == null || _busy ? null : _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share compressed'),
            ),
          ],
        ],
      ),
    );
  }
}
