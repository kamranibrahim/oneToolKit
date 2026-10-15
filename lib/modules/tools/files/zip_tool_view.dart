import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';
import '../../../data/processing/archive_operations.dart';

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
  List<String> _extractedPaths = [];

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
    if (result == null || !mounted) return;
    setState(
      () => _createFiles.addAll(result.files.where((f) => f.path != null)),
    );
  }

  Future<void> _createZip() async {
    if (_createFiles.isEmpty) return;
    setState(() => _busy = true);
    try {
      final inputs = _createFiles
          .map((f) => ArchiveInput(f.path!, f.name))
          .toList();
      final dir = await getTemporaryDirectory();
      final outPath = await ArchiveOperations.create(inputs, dir.path);
      if (!mounted) return;
      await shareFiles(context, [XFile(outPath, mimeType: 'application/zip')]);
      await ToolScaffold.logAction(
        toolId: 'zip_tool',
        toolName: 'ZIP Archive',
        action: 'Created',
        detail: '${_createFiles.length} files',
      );
    } catch (e) {
      if (mounted) setState(() => _extractSummary = 'Create failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extractZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (!mounted ||
        result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }
    setState(() {
      _busy = true;
      _extractedPaths = [];
      _extractSummary = null;
    });
    try {
      final zipPath = result.files.first.path!;
      final dir = await getTemporaryDirectory();
      final paths = await ArchiveOperations.extract(zipPath, dir.path);
      if (!mounted) return;
      setState(() {
        _extractedPaths = paths;
        _extractSummary = 'Extracted ${paths.length} files';
      });
      await ToolScaffold.logAction(
        toolId: 'zip_tool',
        toolName: 'ZIP Archive',
        action: 'Extracted',
        detail: '${paths.length} files',
      );
    } catch (e) {
      if (mounted) setState(() => _extractSummary = 'Extract failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareExtracted(List<String> paths) async {
    try {
      await shareFiles(context, paths.map((path) => XFile(path)).toList());
    } catch (e) {
      if (mounted) setState(() => _extractSummary = 'Share failed: $e');
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
              children: [_buildCreate(), _buildExtract()],
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
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _busy
                            ? null
                            : () =>
                                  setState(() => _createFiles.removeAt(index)),
                      ),
                    );
                  },
                ),
        ),
        if (_extractSummary != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_extractSummary!),
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
            'Extract locally with folders preserved. Supports ZIPs up to 100 MB and 256 MB of extracted files.',
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
          if (_extractedPaths.isNotEmpty) ...[
            if (_extractedPaths
                    .map(p.basename)
                    .map((name) => name.toLowerCase())
                    .toSet()
                    .length ==
                _extractedPaths.length)
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _shareExtracted(_extractedPaths),
                icon: const Icon(Icons.ios_share),
                label: const Text('Share all files'),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Some folders contain files with the same name. Share those files individually.',
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _extractedPaths.length,
                itemBuilder: (context, index) {
                  final path = _extractedPaths[index];
                  return ListTile(
                    title: Text(p.basename(path)),
                    trailing: IconButton(
                      tooltip: 'Share ${p.basename(path)}',
                      icon: const Icon(Icons.ios_share),
                      onPressed: () => _shareExtracted([path]),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
