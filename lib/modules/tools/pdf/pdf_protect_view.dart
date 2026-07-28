import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../widgets/tool_scaffold.dart';

class PdfProtectView extends StatefulWidget {
  const PdfProtectView({super.key});

  @override
  State<PdfProtectView> createState() => _PdfProtectViewState();
}

class _PdfProtectViewState extends State<PdfProtectView> {
  PlatformFile? _file;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
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

  Future<void> _protect() async {
    final file = _file;
    final path = file?.path;
    if (file == null || path == null) {
      ToolScaffold.copy('', message: 'Select a PDF first');
      return;
    }
    final password = _password.text;
    if (password.length < 4) {
      ToolScaffold.copy('', message: 'Password must be at least 4 characters');
      return;
    }
    if (password != _confirm.text) {
      ToolScaffold.copy('', message: 'Passwords do not match');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Encrypting…';
    });
    try {
      final bytes = await File(path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final security = document.security;
      security.userPassword = password;
      security.ownerPassword = password;
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      final outBytes = await document.save();
      document.dispose();

      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        'protected_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(outPath).writeAsBytes(outBytes, flush: true);
      await Share.shareXFiles([
        XFile(outPath, mimeType: 'application/pdf'),
      ]);
      await ToolScaffold.logAction(
        toolId: 'pdf_password',
        toolName: 'Protect PDF',
        action: 'Protected',
        detail: file.name,
      );
      setState(() => _status = 'PDF encrypted with AES-256');
    } catch (e) {
      setState(() => _status = 'Protect failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_password',
      title: 'Protect PDF',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Add AES-256 password protection on device. Keep your password — it cannot be recovered.',
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
                Icons.lock_outline_rounded,
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
              labelText: 'Password',
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
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _file == null || _busy ? null : _protect,
            child: Text(_busy ? 'Encrypting…' : 'Protect & share'),
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
