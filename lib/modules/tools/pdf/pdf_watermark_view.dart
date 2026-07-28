import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_helper.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../widgets/tool_scaffold.dart';
import 'pdf_tool_helpers.dart';

class PdfWatermarkView extends StatefulWidget {
  const PdfWatermarkView({super.key});

  @override
  State<PdfWatermarkView> createState() => _PdfWatermarkViewState();
}

class _PdfWatermarkViewState extends State<PdfWatermarkView> {
  PlatformFile? _file;
  final _text = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.25;
  double _fontSize = 48;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _text.dispose();
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

  Future<void> _apply() async {
    final path = _file?.path;
    final watermark = _text.text.trim();
    if (path == null) {
      ToolScaffold.copy('', message: 'Select a PDF first');
      return;
    }
    if (watermark.isEmpty) {
      ToolScaffold.copy('', message: 'Enter watermark text');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Adding watermark…';
    });
    try {
      final document = await PdfToolHelpers.load(path);
      final font = PdfStandardFont(PdfFontFamily.helvetica, _fontSize);
      final brush = PdfSolidBrush(PdfColor(120, 120, 120));
      final format = PdfStringFormat(alignment: PdfTextAlignment.center);

      for (var i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final size = page.getClientSize();
        final g = page.graphics;
        g.save();
        g.setTransparency(_opacity);
        g.translateTransform(size.width / 2, size.height / 2);
        g.rotateTransform(-45);
        g.drawString(
          watermark,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(-size.width / 2, -_fontSize / 2, size.width, _fontSize),
          format: format,
        );
        g.restore();
      }

      final bytes = await document.save();
      final count = document.pages.count;
      document.dispose();
      final out = await PdfToolHelpers.writeTempPdf(bytes, 'watermarked');
      if (!mounted) return;
      await shareFiles(context, [XFile(out.path, mimeType: 'application/pdf')]);
      await ToolScaffold.logAction(
        toolId: 'pdf_watermark',
        toolName: 'Watermark PDF',
        action: 'Watermarked',
        detail: '$count page(s)',
      );
      setState(() => _status = 'Watermark added to $count page(s)');
    } catch (e) {
      setState(() => _status = 'Watermark failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'pdf_watermark',
      title: 'Watermark PDF',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Stamp diagonal text across every page. Opacity stays light so content remains readable.',
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
            Text(_file!.name, style: theme.textTheme.titleSmall),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Watermark text'),
          ),
          const SizedBox(height: 16),
          Text('Opacity ${(_opacity * 100).round()}%'),
          Slider(
            value: _opacity,
            min: 0.1,
            max: 0.6,
            onChanged: _busy ? null : (v) => setState(() => _opacity = v),
          ),
          Text('Font size ${_fontSize.round()}'),
          Slider(
            value: _fontSize,
            min: 24,
            max: 96,
            divisions: 18,
            onChanged: _busy ? null : (v) => setState(() => _fontSize = v),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _file == null || _busy ? null : _apply,
            child: Text(_busy ? 'Working…' : 'Watermark & share'),
          ),
        ],
      ),
    );
  }
}
