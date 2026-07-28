import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../widgets/tool_scaffold.dart';

class QrScanView extends StatefulWidget {
  const QrScanView({super.key});

  @override
  State<QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<QrScanView> {
  final _controller = MobileScannerController();
  String? _result;
  bool _locked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_locked) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    setState(() {
      _result = raw;
      _locked = true;
    });
    ToolScaffold.logAction(
      toolId: 'qr_scan',
      toolName: 'Scan QR',
      action: 'Scanned',
      detail: raw.length > 40 ? '${raw.substring(0, 40)}…' : raw,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'qr_scan',
      title: 'Scan QR',
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Result',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _result ?? 'Point your camera at a QR code',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _result == null
                              ? null
                              : () => ToolScaffold.copy(_result!),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _result = null;
                            _locked = false;
                          }),
                          child: const Text('Scan again'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
