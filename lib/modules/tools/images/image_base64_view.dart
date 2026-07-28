import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';

class ImageBase64View extends StatefulWidget {
  const ImageBase64View({super.key});

  @override
  State<ImageBase64View> createState() => _ImageBase64ViewState();
}

class _ImageBase64ViewState extends State<ImageBase64View>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _picker = ImagePicker();
  final _decodeInput = TextEditingController();

  String? _encoded;
  String? _sourceName;
  Uint8List? _decodedBytes;
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _decodeInput.dispose();
    super.dispose();
  }

  Future<void> _encodeFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _busy = true;
      _status = 'Encoding…';
    });
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      setState(() {
        _sourceName = file.name;
        _encoded = 'data:$mime;base64,$b64';
        _status = 'Encoded ${bytes.length} bytes';
      });
      await ToolScaffold.logAction(
        toolId: 'image_base64',
        toolName: 'Image ↔ Base64',
        action: 'Encoded',
        detail: file.name,
      );
    } catch (e) {
      setState(() => _status = 'Encode failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _decode() async {
    var raw = _decodeInput.text.trim();
    if (raw.isEmpty) {
      ToolScaffold.copy('', message: 'Paste Base64 first');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Decoding…';
    });
    try {
      if (raw.contains(',')) raw = raw.split(',').last;
      final bytes = base64Decode(raw);
      setState(() {
        _decodedBytes = bytes;
        _status = 'Decoded ${bytes.length} bytes';
      });
      await ToolScaffold.logAction(
        toolId: 'image_base64',
        toolName: 'Image ↔ Base64',
        action: 'Decoded',
        detail: '${bytes.length} B',
      );
    } catch (e) {
      setState(() {
        _decodedBytes = null;
        _status = 'Invalid Base64 image data';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _shareDecoded() async {
    final bytes = _decodedBytes;
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'decoded_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(path).writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(path)]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'image_base64',
      title: 'Image ↔ Base64',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Encode'),
              Tab(text: 'Decode'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Convert a local image to a data URI / Base64 string.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _encodeFromGallery,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_busy ? 'Working…' : 'Choose image'),
                    ),
                    if (_sourceName != null) ...[
                      const SizedBox(height: 8),
                      Text(_sourceName!, style: theme.textTheme.titleSmall),
                    ],
                    if (_encoded != null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        readOnly: true,
                        maxLines: 8,
                        controller: TextEditingController(text: _encoded),
                        decoration: const InputDecoration(labelText: 'Base64'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _encoded!));
                          ToolScaffold.copy(_encoded!, message: 'Base64 copied');
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                    ],
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Paste a Base64 string or data URI to preview and share.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _decodeInput,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Base64 / data URI',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _decode,
                      child: Text(_busy ? 'Working…' : 'Decode'),
                    ),
                    if (_decodedBytes != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_decodedBytes!, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _shareDecoded,
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('Share image'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(_status!, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
