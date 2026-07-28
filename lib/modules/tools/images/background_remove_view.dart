import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_cutout/native_cutout.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

class BackgroundRemoveView extends StatefulWidget {
  const BackgroundRemoveView({super.key});

  @override
  State<BackgroundRemoveView> createState() => _BackgroundRemoveViewState();
}

class _BackgroundRemoveViewState extends State<BackgroundRemoveView> {
  final _picker = ImagePicker();
  String? _sourcePath;
  String? _resultPath;
  bool _cropToSubject = true;
  bool _busy = false;
  double? _downloadFraction;
  String? _status;
  StreamSubscription<ModelDownloadProgress>? _downloadSub;

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureModel() async {
    if (!Platform.isAndroid) return;
    final ready = await NativeCutout.isModelAvailable();
    if (ready) return;

    setState(() {
      _status = 'Downloading on-device model…';
      _downloadFraction = 0;
    });
    _downloadSub?.cancel();
    _downloadSub = NativeCutout.downloadProgress.listen((progress) {
      if (!mounted) return;
      setState(() => _downloadFraction = progress.fraction);
    });
    final ok = await NativeCutout.downloadModel();
    await _downloadSub?.cancel();
    _downloadSub = null;
    if (!ok) {
      throw Exception('Could not download segmentation model. Check network.');
    }
    setState(() => _downloadFraction = null);
  }

  Future<void> _pickAndCut() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _busy = true;
      _sourcePath = file.path;
      _resultPath = null;
      _status = 'Preparing…';
      _downloadFraction = null;
    });

    try {
      await _ensureModel();
      setState(() => _status = 'Removing background…');
      final result = await NativeCutout.removeBackground(
        file.path,
        options: CutoutOptions(
          cropToSubject: _cropToSubject,
          writeToCache: true,
        ),
      );

      switch (result) {
        case CutoutFileSuccess(:final path):
          setState(() {
            _resultPath = path;
            _status = 'Done — transparent PNG ready';
          });
          await ToolScaffold.logAction(
            toolId: 'bg_remove',
            toolName: 'Background Removal',
            action: 'Removed background',
            detail: p.basename(file.path),
          );
        case CutoutBytesSuccess():
          setState(() => _status = 'Unexpected bytes result');
        case CutoutFailure(:final code, :final message):
          setState(() => _status = _friendlyError(code, message));
      }
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(CutoutErrorCode code, String message) {
    return switch (code) {
      CutoutErrorCode.invalidInput => 'Could not read that image.',
      CutoutErrorCode.noSubjectFound =>
        'No clear subject found — try a photo with a stronger subject.',
      CutoutErrorCode.processingFailed =>
        Platform.isIOS
            ? 'Needs iOS 17+ on a real device. $message'
            : message,
    };
  }

  Future<void> _share() async {
    final path = _resultPath;
    if (path == null) return;
    if (!mounted) return;
    await shareFiles(context, [XFile(path, mimeType: 'image/png')]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'bg_remove',
      title: 'Background Removal',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'On-device cutout — Android ML Kit / iOS Vision. Nothing is uploaded.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Crop to subject'),
            subtitle: const Text('Trim transparent margins'),
            value: _cropToSubject,
            onChanged: _busy ? null : (v) => setState(() => _cropToSubject = v),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _pickAndCut,
            icon: const Icon(Icons.layers_clear_rounded),
            label: Text(_busy ? 'Working…' : 'Choose photo'),
          ),
          if (_downloadFraction != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _downloadFraction),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_sourcePath != null || _resultPath != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (_sourcePath != null)
                  Expanded(
                    child: _Preview(
                      label: 'Original',
                      child: Image.file(File(_sourcePath!), fit: BoxFit.contain),
                    ),
                  ),
                if (_sourcePath != null && _resultPath != null)
                  const SizedBox(width: 12),
                if (_resultPath != null)
                  Expanded(
                    child: _Preview(
                      label: 'Cutout',
                      child: ColoredBox(
                        color: const Color(0xFFE5E5EA),
                        child: Image.file(
                          File(_resultPath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (_resultPath != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share PNG'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
      ],
    );
  }
}
