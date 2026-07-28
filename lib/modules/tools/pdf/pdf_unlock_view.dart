import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../widgets/tool_scaffold.dart';

class PdfUnlockView extends StatefulWidget {
  const PdfUnlockView({super.key});

  @override
  State<PdfUnlockView> createState() => _PdfUnlockViewState();
}

class _PdfUnlockViewState extends State<PdfUnlockView> {
  PlatformFile? _file;
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _file = result.files.first;
      _status = null;
    });
  }

  Future<void> _unlock() async {
    final file = _file;
    final path = file?.path;
    if (file == null || path == null) {
      ToolScaffold.copy('', message: 'Select a PDF first');
      return;
    }
    if (_password.text.isEmpty) {
      ToolScaffold.copy('', message: 'Enter the PDF password');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Unlocking…';
    });
    try {
      final bytes = await File(path).readAsBytes();
      final document = PdfDocument(
        inputBytes: bytes,
        password: _password.text,
      );
      document.security.userPassword = '';
      document.security.ownerPassword = '';
      final outBytes = await document.save();
      document.dispose();

      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        'unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(outPath).writeAsBytes(outBytes, flush: true);
      await Share.shareXFiles([
        XFile(outPath, mimeType: 'application/pdf'),
      ]);
      await ToolScaffold.logAction(
        toolId: 'pdf_unlock',
        toolName: 'Unlock PDF',
        action: 'Unlocked',
        detail: file.name,
      );
      setState(() => _status = 'Password removed');
    } catch (e) {
      setState(() => _status = 'Unlock failed — check the password');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_unlock',
      title: 'Unlock PDF',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Remove password protection when you know the current password. Runs fully offline.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_file == null ? 'Choose PDF' : 'Change PDF'),
          ),
          if (_file != null) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.lock_open_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(_file!.name),
              subtitle: Text(_sizeLabel(_file!.size)),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscure,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: 'Current password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _file == null || _busy ? null : _unlock,
            child: Text(_busy ? 'Unlocking…' : 'Unlock & share'),
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
