import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../widgets/tool_scaffold.dart';

class DuplicateFinderView extends StatefulWidget {
  const DuplicateFinderView({super.key});

  @override
  State<DuplicateFinderView> createState() => _DuplicateFinderViewState();
}

class _DuplicateFinderViewState extends State<DuplicateFinderView> {
  bool _busy = false;
  String? _status;
  List<_DupGroup> _groups = [];

  Future<void> _scan() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _busy = true;
      _status = 'Hashing ${result.files.length} file(s)…';
      _groups = [];
    });

    try {
      final byHash = <String, List<PlatformFile>>{};
      for (final file in result.files) {
        if (file.path == null) continue;
        final bytes = await File(file.path!).readAsBytes();
        final digest = md5.convert(bytes).toString();
        byHash.putIfAbsent(digest, () => []).add(file);
      }

      final groups = byHash.entries
          .where((e) => e.value.length > 1)
          .map(
            (e) => _DupGroup(
              hash: e.key,
              files: e.value,
              size: e.value.first.size,
            ),
          )
          .toList()
        ..sort((a, b) => b.files.length.compareTo(a.files.length));

      setState(() {
        _groups = groups;
        _status = groups.isEmpty
            ? 'No duplicates found'
            : '${groups.length} duplicate group(s)';
      });

      await ToolScaffold.logAction(
        toolId: 'duplicate_finder',
        toolName: 'Duplicate Finder',
        action: 'Scanned',
        detail: '${result.files.length} files',
      );
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'duplicate_finder',
      title: 'Duplicate Finder',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select multiple files. Matching MD5 hashes are grouped as duplicates — all hashing stays on device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _scan,
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(_busy ? 'Scanning…' : 'Choose files'),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          Expanded(
            child: _groups.isEmpty
                ? const Center(child: Text('Duplicate groups appear here'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return Card(
                        child: ExpansionTile(
                          title: Text('${group.files.length} duplicates'),
                          subtitle: Text(
                            '${_sizeLabel(group.size)} · ${group.hash.substring(0, 8)}…',
                          ),
                          children: group.files
                              .map(
                                (f) => ListTile(
                                  dense: true,
                                  title: Text(
                                    f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(p.dirname(f.path ?? '')),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
          ),
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

class _DupGroup {
  _DupGroup({
    required this.hash,
    required this.files,
    required this.size,
  });

  final String hash;
  final List<PlatformFile> files;
  final int size;
}
