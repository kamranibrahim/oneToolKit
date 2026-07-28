import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class Base64View extends StatefulWidget {
  const Base64View({super.key});

  @override
  State<Base64View> createState() => _Base64ViewState();
}

class _Base64ViewState extends State<Base64View> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  String? _error;

  void _encode() {
    try {
      _output.text = base64Encode(utf8.encode(_input.text));
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = 'Encode failed');
    }
  }

  void _decode() {
    try {
      _output.text = utf8.decode(base64Decode(_input.text.trim()));
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = 'Invalid Base64');
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
      toolId: 'base64',
      title: 'Base64',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Input…',
              errorText: _error,
            ),
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
            maxLines: 6,
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Output'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy output'),
          ),
        ],
      ),
    );
  }
}
