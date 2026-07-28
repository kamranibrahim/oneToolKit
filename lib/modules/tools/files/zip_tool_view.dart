import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/tool_scaffold.dart';

class ZipToolView extends StatefulWidget {
  const ZipToolView({super.key});

  @override
  State<ZipToolView> createState() => _ZipToolViewState();
}

class _ZipToolViewState extends State<ZipToolView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _createFiles = <PlatformFile>[];
  String? _extractSummary;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickCreateFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() => _createFiles.addAll(result.files.where((f) => f.path != null)));
  }

  Future<void> _createZip() async {
    if (_createFiles.isEmpty) return;
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        'archive_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      final encoder = ZipFileEncoder()..create(outPath);
      for (final file in _createFiles) {
        await encoder.addFile(File(file.path!), file.name);
      }
      await encoder.close();
      await Share.shareXFiles([XFile(outPath, mimeType: 'application/zip')]);
      await ToolScaffold.logAction(
        toolId: 'zip_tool',
        toolName: 'ZIP Archive',
        action: 'Created',
        detail: '${_createFiles.length} files',
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _extractZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final zipPath = result.files.first.path!;
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final dir = await getTemporaryDirectory();
      final outDir = Directory(
        p.join(dir.path, 'unzip_${DateTime.now().millisecondsSinceEpoch}'),
      );
      await outDir.create(recursive: true);

      final extracted = <XFile>[];
      for (final file in archive) {
        if (!file.isFile) continue;
        final outPath = p.join(outDir.path, p.basename(file.name));
        final out = File(outPath);
        await out.writeAsBytes(file.content as List<int>);
        extracted.add(XFile(outPath));
      }

      setState(() => _extractSummary = 'Extracted ${extracted.length} file(s)');
      if (extracted.isNotEmpty) {
        await Share.shareXFiles(extracted);
      }
      await ToolScaffold.logAction(
        toolId: 'zip_tool',
        toolName: 'ZIP Archive',
        action: 'Extracted',
        detail: '${extracted.length} files',
      );
    } catch (e) {
      setState(() => _extractSummary = 'Extract failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'zip_tool',
      title: 'ZIP Archive',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Create'),
              Tab(text: 'Extract'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildCreate(),
                _buildExtract(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreate() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _pickCreateFiles,
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Add files'),
          ),
        ),
        Expanded(
          child: _createFiles.isEmpty
              ? const Center(child: Text('No files selected'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _createFiles.length,
                  itemBuilder: (context, index) {
                    final file = _createFiles[index];
                    return ListTile(
                      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            setState(() => _createFiles.removeAt(index)),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _createFiles.isEmpty || _busy ? null : _createZip,
            child: Text(_busy ? 'Creating…' : 'Create ZIP & share'),
          ),
        ),
      ],
    );
  }

  Widget _buildExtract() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pick a ZIP file to extract locally, then share the contents.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _extractZip,
            icon: const Icon(Icons.folder_zip_rounded),
            label: Text(_busy ? 'Extracting…' : 'Choose ZIP'),
          ),
          if (_extractSummary != null) ...[
            const SizedBox(height: 16),
            Text(_extractSummary!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
