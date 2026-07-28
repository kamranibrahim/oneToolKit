import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../widgets/tool_scaffold.dart';

class FileChecksumView extends StatefulWidget {
  const FileChecksumView({super.key});

  @override
  State<FileChecksumView> createState() => _FileChecksumViewState();
}

class _FileChecksumViewState extends State<FileChecksumView> {
  String? _name;
  String? _md5;
  String? _sha1;
  String? _sha256;
  int? _size;
  bool _busy = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }
    setState(() {
      _busy = true;
      _name = result.files.first.name;
      _md5 = _sha1 = _sha256 = null;
      _size = result.files.first.size;
    });
    try {
      final bytes = await File(result.files.first.path!).readAsBytes();
      setState(() {
        _md5 = md5.convert(bytes).toString();
        _sha1 = sha1.convert(bytes).toString();
        _sha256 = sha256.convert(bytes).toString();
        _size = bytes.length;
      });
      await ToolScaffold.logAction(
        toolId: 'checksum',
        toolName: 'File Checksum',
        action: 'Hashed',
        detail: p.basename(_name ?? 'file'),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'checksum',
      title: 'File Checksum',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.file_present_rounded),
            label: Text(_busy ? 'Computing…' : 'Choose file'),
          ),
          if (_name != null) ...[
            const SizedBox(height: 16),
            Text(_name!, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Size: ${_sizeLabel(_size)}'),
            const SizedBox(height: 12),
            _HashTile(label: 'MD5', value: _md5),
            _HashTile(label: 'SHA-1', value: _sha1),
            _HashTile(label: 'SHA-256', value: _sha256),
          ],
        ],
      ),
    );
  }

  String _sizeLabel(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _HashTile extends StatelessWidget {
  const _HashTile({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: SelectableText(
          value ?? '—',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        trailing: value == null
            ? null
            : IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => ToolScaffold.copy(value!),
              ),
      ),
    );
  }
}
