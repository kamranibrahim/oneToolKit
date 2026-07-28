import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../widgets/tool_scaffold.dart';

class QrGenerateView extends StatefulWidget {
  const QrGenerateView({super.key});

  @override
  State<QrGenerateView> createState() => _QrGenerateViewState();
}

class _QrGenerateViewState extends State<QrGenerateView> {
  final _controller = TextEditingController();
  String _data = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'qr_generate',
      title: 'Generate QR',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter text, URL, or data…',
            ),
            onChanged: (v) => setState(() => _data = v.trim()),
          ),
          const SizedBox(height: 24),
          if (_data.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _data,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
            )
          else
            Container(
              height: 240,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'QR preview appears here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_data.isNotEmpty)
            FilledButton(
              onPressed: () {
                ToolScaffold.logAction(
                  toolId: 'qr_generate',
                  toolName: 'Generate QR',
                  action: 'Generated',
                  detail: _data.length > 40 ? '${_data.substring(0, 40)}…' : _data,
                );
                ToolScaffold.copy(_data, message: 'Data copied');
              },
              child: const Text('Copy data'),
            ),
        ],
      ),
    );
  }
}
