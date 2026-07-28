import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../widgets/tool_scaffold.dart';

class ImageMetadataView extends StatefulWidget {
  const ImageMetadataView({super.key});

  @override
  State<ImageMetadataView> createState() => _ImageMetadataViewState();
}

class _ImageMetadataViewState extends State<ImageMetadataView> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _name;
  String? _path;
  final _rows = <_MetaRow>[];

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _busy = true;
      _rows.clear();
      _name = file.name;
      _path = file.path;
    });
    try {
      final bytes = await File(file.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      final size = await File(file.path).length();
      final rows = <_MetaRow>[
        _MetaRow('File', file.name),
        _MetaRow('Path', file.path),
        _MetaRow('Size', _sizeLabel(size)),
        _MetaRow('Format', p.extension(file.path).replaceFirst('.', '').toUpperCase()),
      ];
      if (decoded != null) {
        rows.addAll([
          _MetaRow('Width', '${decoded.width} px'),
          _MetaRow('Height', '${decoded.height} px'),
          _MetaRow('Channels', '${decoded.numChannels}'),
          _MetaRow('Bits/channel', '${decoded.bitsPerChannel}'),
          _MetaRow('Has alpha', decoded.hasAlpha ? 'Yes' : 'No'),
        ]);
        _appendExif(decoded, rows);
      } else {
        rows.add(const _MetaRow('Decode', 'Could not decode image pixels'));
      }
      setState(() => _rows.addAll(rows));
      await ToolScaffold.logAction(
        toolId: 'image_metadata',
        toolName: 'Image Metadata',
        action: 'Inspected',
        detail: file.name,
      );
    } catch (e) {
      setState(() => _rows.add(_MetaRow('Error', '$e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  void _appendExif(img.Image image, List<_MetaRow> rows) {
    final exif = image.exif;
    if (exif.isEmpty) {
      rows.add(const _MetaRow('EXIF', 'None found'));
      return;
    }
    for (final ifdName in exif.keys) {
      final ifd = exif[ifdName];
      for (final tag in ifd.keys) {
        final name = exif.getTagName(tag);
        final value = ifd[tag]?.toString() ?? '';
        if (value.isEmpty) continue;
        rows.add(_MetaRow('$ifdName · $name', value));
      }
      for (final subName in ifd.sub.keys) {
        final sub = ifd.sub[subName];
        for (final tag in sub.keys) {
          final name = exif.getTagName(tag);
          final value = sub[tag]?.toString() ?? '';
          if (value.isEmpty) continue;
          rows.add(_MetaRow('$ifdName/$subName · $name', value));
        }
      }
    }
  }

  Future<void> _copyAll() async {
    if (_rows.isEmpty) return;
    final text = _rows.map((r) => '${r.label}: ${r.value}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    ToolScaffold.copy(text, message: 'Metadata copied');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'image_metadata',
      title: 'Image Metadata',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Inspect dimensions, format, and EXIF tags without uploading anything.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.info_outline_rounded),
            label: Text(_busy ? 'Reading…' : 'Choose image'),
          ),
          if (_path != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_path!),
                height: 180,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            if (_name != null) ...[
              const SizedBox(height: 8),
              Text(_name!, style: theme.textTheme.titleSmall),
            ],
          ],
          if (_rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copyAll,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy all'),
              ),
            ),
            ..._rows.map(
              (row) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(row.label, style: theme.textTheme.labelMedium),
                subtitle: SelectableText(row.value),
              ),
            ),
          ],
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

class _MetaRow {
  const _MetaRow(this.label, this.value);
  final String label;
  final String value;
}
