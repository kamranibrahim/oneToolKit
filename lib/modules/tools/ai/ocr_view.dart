import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/share_helper.dart';
import '../../../widgets/tool_scaffold.dart';

class OcrView extends StatefulWidget {
  const OcrView({super.key});

  @override
  State<OcrView> createState() => _OcrViewState();
}

class _OcrViewState extends State<OcrView> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _editor = TextEditingController();
  String _original = '';
  String? _imagePath;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _recognizer.close();
    _editor.dispose();
    super.dispose();
  }

  int get _words {
    final t = _editor.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  Future<void> _run(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;
    setState(() {
      _busy = true;
      _status = 'Recognizing text…';
      _imagePath = file.path;
      _editor.clear();
      _original = '';
    });
    try {
      final input = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(input);
      final text = result.text.trim();
      setState(() {
        _original = text;
        _editor.text = text;
        _status = text.isEmpty
            ? 'No text found — try a clearer photo'
            : '${result.blocks.length} block(s) · $_words words · tap to edit';
      });
      if (text.isNotEmpty) {
        await ToolScaffold.logAction(
          toolId: 'ai_ocr',
          toolName: 'OCR',
          action: 'Extracted',
          detail: '${text.length} chars',
        );
      }
    } catch (e) {
      setState(() => _status = 'OCR failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _editor.text = _original;
      _status = _original.isEmpty
          ? 'No text found'
          : 'Reset to original extraction';
    });
  }

  Future<void> _shareText() async {
    final text = _editor.text.trim();
    if (text.isEmpty) return;
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'ocr_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await File(path).writeAsString(text);
    if (!mounted) return;
    await shareFiles(
      context,
      [XFile(path, mimeType: 'text/plain', name: 'ocr-text.txt')],
    );
    await ToolScaffold.logAction(
      toolId: 'ai_ocr',
      toolName: 'OCR',
      action: 'Shared',
      detail: '${text.length} chars',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _editor.text.trim().isNotEmpty;
    final dirty = _editor.text != _original && _original.isNotEmpty;

    return ToolScaffold(
      toolId: 'ai_ocr',
      title: 'OCR',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Extract text on-device, then edit before copying or sharing.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _busy ? null : () => _run(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed:
                            _busy ? null : () => _run(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          if (_imagePath != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _editor,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Recognized text appears here — edit freely',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (hasText || dirty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${_editor.text.length} chars · $_words words'
                    '${dirty ? ' · edited' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (dirty)
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                ],
              ),
            ),
          if (hasText)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => ToolScaffold.copy(_editor.text),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareText,
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
