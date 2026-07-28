import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/tool_scaffold.dart';

class BarcodeGenerateView extends StatefulWidget {
  const BarcodeGenerateView({super.key});

  @override
  State<BarcodeGenerateView> createState() => _BarcodeGenerateViewState();
}

class _BarcodeGenerateViewState extends State<BarcodeGenerateView> {
  final _controller = TextEditingController(text: 'ONETOOLKIT');
  String _format = 'Code 128';

  Barcode get _barcode => switch (_format) {
        'Code 39' => Barcode.code39(),
        'EAN-13' => Barcode.ean13(),
        'EAN-8' => Barcode.ean8(),
        'UPC-A' => Barcode.upcA(),
        'QR' => Barcode.qrCode(),
        'Data Matrix' => Barcode.dataMatrix(),
        _ => Barcode.code128(),
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _controller.text.trim();
    final isMatrix = _format == 'QR' || _format == 'Data Matrix';
    return ToolScaffold(
      toolId: 'barcode_generate',
      title: 'Barcode Generate',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Create barcodes offline for inventory, tickets, and product labels.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _format,
            decoration: const InputDecoration(labelText: 'Format'),
            items: const [
              'Code 128',
              'Code 39',
              'EAN-13',
              'EAN-8',
              'UPC-A',
              'QR',
              'Data Matrix',
            ]
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _format = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Content',
              helperText: _format.startsWith('EAN') || _format == 'UPC-A'
                  ? 'Numeric product codes only for this format'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          if (value.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BarcodeWidget(
                  barcode: _barcode,
                  data: value,
                  width: 280,
                  height: isMatrix ? 280 : 120,
                  drawText: true,
                  errorBuilder: (context, error) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Invalid data for $_format.\nTry Code 128 for free-form text.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: value.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: value));
                    ToolScaffold.copy(value, message: 'Content copied');
                    ToolScaffold.logAction(
                      toolId: 'barcode_generate',
                      toolName: 'Barcode Generate',
                      action: 'Generated',
                      detail: _format,
                    );
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy content'),
          ),
        ],
      ),
    );
  }
}
