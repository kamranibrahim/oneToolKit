import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/tool_scaffold.dart';

class OcrView extends StatefulWidget {
  const OcrView({super.key});

  @override
  State<OcrView> createState() => _OcrViewState();
}

class _OcrViewState extends State<OcrView> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String _text = '';
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _run(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;
    setState(() {
      _busy = true;
      _status = 'Recognizing text…';
      _text = '';
    });
    try {
      final input = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(input);
      setState(() {
        _text = result.text.trim();
        _status = _text.isEmpty
            ? 'No text found'
            : '${result.blocks.length} block(s) · ${_text.split(RegExp(r'\s+')).length} words';
      });
      if (_text.isNotEmpty) {
        await ToolScaffold.logAction(
          toolId: 'ai_ocr',
          toolName: 'OCR',
          action: 'Extracted',
          detail: '${_text.length} chars',
        );
      }
    } catch (e) {
      setState(() => _status = 'OCR failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Extract text from photos on-device with ML Kit. Nothing is uploaded.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _run(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : () => _run(ImageSource.gallery),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _text.isEmpty ? 'Recognized text appears here' : _text,
                  ),
                ),
              ),
            ),
          ),
          if (_text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: () => ToolScaffold.copy(_text),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy text'),
              ),
            ),
        ],
      ),
    );
  }
}
