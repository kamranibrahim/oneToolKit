import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';
import '../../../data/processing/archive_operations.dart';
import '../../../data/processing/file_names.dart';

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
    if (result == null || !mounted) return;
    setState(() {
      _files
        ..clear()
        ..addAll(result.files.where((f) => f.path != null));
      _status = '${_files.length} file(s)';
    });
  }

  List<String> _names() => FileNames.rename(
    _files.map((f) => f.name).toList(),
    _pattern.text,
    _start,
  );

  Future<void> _export() async {
    if (_files.isEmpty) return;
    setState(() {
      _busy = true;
      _status = 'Preparing renamed copies…';
    });
    try {
      final names = _names();
      final inputs = [
        for (var i = 0; i < _files.length; i++)
          ArchiveInput(_files[i].path!, names[i]),
      ];
      final dir = await getTemporaryDirectory();
      final zipPath = await ArchiveOperations.create(inputs, dir.path);
      if (!mounted) return;
      await shareFiles(context, [XFile(zipPath, mimeType: 'application/zip')]);
      await ToolScaffold.logAction(
        toolId: 'batch_rename',
        toolName: 'Batch Rename',
        action: 'Renamed',
        detail: '${_files.length} files',
      );
      if (mounted) {
        setState(() => _status = 'Prepared ${names.length} renamed files');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Rename failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<String>? names;
    String? validationError;
    try {
      names = _names();
    } catch (e) {
      validationError = e.toString().replaceFirst('FormatException: ', '');
    }
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
                subtitle: Text(
                  names == null ? 'Invalid output name' : '→ ${names[i]}',
                ),
              );
            }),
          ],
          if (validationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                validationError,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _files.isEmpty || _busy || validationError != null
                ? null
                : _export,
            child: Text(_busy ? 'Working…' : 'Export renamed ZIP'),
          ),
        ],
      ),
    );
  }
}
