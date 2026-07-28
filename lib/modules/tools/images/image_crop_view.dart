import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';

class ImageCropView extends StatefulWidget {
  const ImageCropView({super.key});

  @override
  State<ImageCropView> createState() => _ImageCropViewState();
}

class _ImageCropViewState extends State<ImageCropView> {
  final _picker = ImagePicker();
  String? _croppedPath;
  bool _busy = false;

  Future<void> _pickAndCrop() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF0D9488),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF0D9488),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (cropped == null) return;
      setState(() => _croppedPath = cropped.path);
      await ToolScaffold.logAction(
        toolId: 'image_crop',
        toolName: 'Crop Image',
        action: 'Cropped',
        detail: p.basename(cropped.path),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'image_crop',
      title: 'Crop Image',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pickAndCrop,
            icon: const Icon(Icons.crop_rounded),
            label: Text(_busy ? 'Opening cropper…' : 'Choose & crop'),
          ),
          if (_croppedPath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_croppedPath!), fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Share.shareXFiles([XFile(_croppedPath!)]),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share cropped image'),
            ),
          ],
        ],
      ),
    );
  }
}
