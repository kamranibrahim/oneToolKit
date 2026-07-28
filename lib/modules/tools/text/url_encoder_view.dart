import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class UrlEncoderView extends StatefulWidget {
  const UrlEncoderView({super.key});

  @override
  State<UrlEncoderView> createState() => _UrlEncoderViewState();
}

class _UrlEncoderViewState extends State<UrlEncoderView> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  String? _error;

  void _encode() {
    try {
      _output.text = Uri.encodeComponent(_input.text);
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = 'Encode failed');
    }
  }

  void _decode() {
    try {
      _output.text = Uri.decodeComponent(_input.text);
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = 'Invalid URL encoding');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'url_encoder',
      title: 'URL Encoder',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 4,
            decoration: InputDecoration(hintText: 'Input…', errorText: _error),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(onPressed: _encode, child: const Text('Encode')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(onPressed: _decode, child: const Text('Decode')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _output,
            maxLines: 4,
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Output'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
