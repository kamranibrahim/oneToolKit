import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';

import '../../../widgets/tool_scaffold.dart';

class DocumentScannerView extends StatefulWidget {
  const DocumentScannerView({super.key});

  @override
  State<DocumentScannerView> createState() => _DocumentScannerViewState();
}

class _DocumentScannerViewState extends State<DocumentScannerView> {
  final _paths = <String>[];
  bool _busy = false;
  String? _status;
  bool _exportAsPdf = true;

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        asPdf: _exportAsPdf,
        scannerSource: ScannerSource.cameraAndGallery,
        iosScannerOptions: const IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.85,
        ),
      );
      if (pictures == null || pictures.isEmpty) {
        setState(() => _status = 'Scan cancelled');
        return;
      }
      setState(() {
        _paths
          ..clear()
          ..addAll(pictures);
        _status = _exportAsPdf
            ? 'Scanned to PDF'
            : 'Scanned ${pictures.length} page(s)';
      });
      await ToolScaffold.logAction(
        toolId: 'doc_scanner',
        toolName: 'Scan to PDF',
        action: 'Scanned',
        detail: _exportAsPdf
            ? p.basename(pictures.first)
            : '${pictures.length} images',
      );
    } on ArgumentError catch (e) {
      setState(() => _status = 'Invalid option: $e');
    } on CunningDocumentScannerException catch (e) {
      setState(() => _status = e.message);
    } catch (e) {
      setState(() => _status = 'Scan failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_paths.isEmpty) return;
    final files = _paths
        .map(
          (path) => XFile(
            path,
            mimeType: path.toLowerCase().endsWith('.pdf')
                ? 'application/pdf'
                : 'image/jpeg',
          ),
        )
        .toList();
    if (!mounted) return;
    await shareFiles(context, files);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'doc_scanner',
      title: 'Scan to PDF',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Capture documents with automatic edge detection. Processing stays on your device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Export as PDF'),
            subtitle: const Text('Off exports cropped page images'),
            value: _exportAsPdf,
            onChanged: _busy
                ? null
                : (v) => setState(() {
                      _exportAsPdf = v;
                      _paths.clear();
                      _status = null;
                    }),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _scan,
            icon: const Icon(Icons.document_scanner_rounded),
            label: Text(_busy ? 'Opening scanner…' : 'Start scan'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
          if (_paths.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._paths.map((path) {
              final isPdf = path.toLowerCase().endsWith('.pdf');
              if (isPdf) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(p.basename(path)),
                  subtitle: Text(_sizeLabel(File(path).lengthSync())),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
              );
            }),
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(_exportAsPdf ? 'Share PDF' : 'Share images'),
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
