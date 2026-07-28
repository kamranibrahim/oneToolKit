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

class ImageRotateView extends StatefulWidget {
  const ImageRotateView({super.key});

  @override
  State<ImageRotateView> createState() => _ImageRotateViewState();
}

class _ImageRotateViewState extends State<ImageRotateView> {
  final _picker = ImagePicker();
  Uint8List? _bytes;
  img.Image? _image;
  bool _busy = false;

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    setState(() {
      _image = decoded;
      _bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
    });
  }

  void _rotate(int degrees) {
    if (_image == null) return;
    final rotated = img.copyRotate(_image!, angle: degrees);
    setState(() {
      _image = rotated;
      _bytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 92));
    });
  }

  void _flip({required bool horizontal}) {
    if (_image == null) return;
    final flipped = horizontal
        ? img.flipHorizontal(_image!)
        : img.flipVertical(_image!);
    setState(() {
      _image = flipped;
      _bytes = Uint8List.fromList(img.encodeJpg(flipped, quality: 92));
    });
  }

  Future<void> _share() async {
    if (_bytes == null) return;
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'rotated_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(path).writeAsBytes(_bytes!);
      if (!mounted) return;
      await shareFiles(context, [XFile(path)]);
      await ToolScaffold.logAction(
        toolId: 'image_rotate',
        toolName: 'Rotate Image',
        action: 'Exported',
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'image_rotate',
      title: 'Rotate Image',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose image'),
          ),
          if (_bytes != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(_bytes!, height: 240, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.rotate_left_rounded, size: 18),
                  label: const Text('−90°'),
                  onPressed: () => _rotate(-90),
                ),
                ActionChip(
                  avatar: const Icon(Icons.rotate_right_rounded, size: 18),
                  label: const Text('+90°'),
                  onPressed: () => _rotate(90),
                ),
                ActionChip(
                  avatar: const Icon(Icons.flip_rounded, size: 18),
                  label: const Text('Flip H'),
                  onPressed: () => _flip(horizontal: true),
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Flip V'),
                  onPressed: () => _flip(horizontal: false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share'),
            ),
          ],
        ],
      ),
    );
  }
}
