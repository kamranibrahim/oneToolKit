import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';

class BatchRenameView extends StatefulWidget {
  const BatchRenameView({super.key});

  @override
  State<BatchRenameView> createState() => _BatchRenameViewState();
}

class _BatchRenameViewState extends State<BatchRenameView> {
  final _files = <PlatformFile>[];
  final _pattern = TextEditingController(text: '{name}_{n}');
  int _start = 1;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _pattern.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() {
      _files
        ..clear()
        ..addAll(result.files.where((f) => f.path != null));
      _status = '${_files.length} file(s)';
    });
  }

  String _newName(PlatformFile file, int index) {
    final original = file.name;
    final stem = p.basenameWithoutExtension(original);
    final ext = p.extension(original); // includes dot
    final n = (_start + index).toString().padLeft(2, '0');
    var out = _pattern.text
        .replaceAll('{name}', stem)
        .replaceAll('{n}', n)
        .replaceAll('{ext}', ext.replaceFirst('.', ''));
    if (!out.contains('.') && ext.isNotEmpty) out = '$out$ext';
    return out;
  }

  Future<void> _export() async {
    if (_files.isEmpty) return;
    setState(() {
      _busy = true;
      _status = 'Preparing renamed copies…';
    });
    try {
      final dir = await getTemporaryDirectory();
      final work = Directory(
        p.join(dir.path, 'rename_${DateTime.now().millisecondsSinceEpoch}'),
      );
      await work.create(recursive: true);

      final outputs = <File>[];
      for (var i = 0; i < _files.length; i++) {
        final src = File(_files[i].path!);
        final dest = File(p.join(work.path, _newName(_files[i], i)));
        await src.copy(dest.path);
        outputs.add(dest);
      }

      final zipPath = p.join(
        dir.path,
        'renamed_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      final encoder = ZipFileEncoder()..create(zipPath);
      for (final file in outputs) {
        await encoder.addFile(file, p.basename(file.path));
      }
      await encoder.close();

      await Share.shareXFiles([XFile(zipPath, mimeType: 'application/zip')]);
      await ToolScaffold.logAction(
        toolId: 'batch_rename',
        toolName: 'Batch Rename',
        action: 'Renamed',
        detail: '${_files.length} files',
      );
      setState(() => _status = 'Exported ${_files.length} renamed file(s)');
    } catch (e) {
      setState(() => _status = 'Rename failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'batch_rename',
      title: 'Batch Rename',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Preview new names with {name}, {n}, and {ext}. Exports renamed copies as a ZIP — originals stay untouched.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.folder_open_rounded),
            label: Text(_files.isEmpty ? 'Choose files' : 'Change files'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pattern,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Pattern',
              hintText: '{name}_{n}',
              helperText: '{name} stem · {n} number · {ext} extension',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text('Start number $_start'),
          Slider(
            value: _start.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: _busy ? null : (v) => setState(() => _start = v.round()),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Preview', style: theme.textTheme.titleSmall),
            ...List.generate(_files.length, (i) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  _files[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('→ ${_newName(_files[i], i)}'),
              );
            }),
          ],
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _files.isEmpty || _busy ? null : _export,
            child: Text(_busy ? 'Working…' : 'Export renamed ZIP'),
          ),
        ],
      ),
    );
  }
}
