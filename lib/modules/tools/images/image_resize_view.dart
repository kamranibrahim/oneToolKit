import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';

class ImageResizeView extends StatefulWidget {
  const ImageResizeView({super.key});

  @override
  State<ImageResizeView> createState() => _ImageResizeViewState();
}

class _ImageResizeViewState extends State<ImageResizeView> {
  final _picker = ImagePicker();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  XFile? _file;
  int? _srcW;
  int? _srcH;
  bool _keepAspect = true;
  bool _busy = false;

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    setState(() {
      _file = file;
      _srcW = decoded.width;
      _srcH = decoded.height;
      _widthCtrl.text = '${decoded.width}';
      _heightCtrl.text = '${decoded.height}';
    });
  }

  void _onWidthChanged(String v) {
    if (!_keepAspect || _srcW == null || _srcH == null) return;
    final w = int.tryParse(v);
    if (w == null || w <= 0) return;
    final h = (w * _srcH! / _srcW!).round();
    _heightCtrl.text = '$h';
  }

  Future<void> _export() async {
    if (_file == null) return;
    final w = int.tryParse(_widthCtrl.text);
    final h = int.tryParse(_heightCtrl.text);
    if (w == null || h == null || w <= 0 || h <= 0) return;
    setState(() => _busy = true);
    try {
      final bytes = await _file!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('decode failed');
      final resized = img.copyResize(decoded, width: w, height: h);
      final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: 90));
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'resized_${w}x$h.jpg');
      await File(path).writeAsBytes(encoded);
      await Share.shareXFiles([XFile(path)]);
      await ToolScaffold.logAction(
        toolId: 'image_resize',
        toolName: 'Resize Image',
        action: 'Resized',
        detail: '${_srcW}x$_srcH → ${w}x$h',
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'image_resize',
      title: 'Resize Image',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose image'),
          ),
          if (_file != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_file!.path), height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text('Original: $_srcW×$_srcH'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Width'),
                    onChanged: _onWidthChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep aspect ratio'),
              value: _keepAspect,
              onChanged: (v) => setState(() => _keepAspect = v),
            ),
            FilledButton(
              onPressed: _busy ? null : _export,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Export & share'),
            ),
          ],
        ],
      ),
    );
  }
}
