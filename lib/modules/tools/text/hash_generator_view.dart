import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class HashGeneratorView extends StatefulWidget {
  const HashGeneratorView({super.key});

  @override
  State<HashGeneratorView> createState() => _HashGeneratorViewState();
}

class _HashGeneratorViewState extends State<HashGeneratorView> {
  final _controller = TextEditingController();
  String _md5 = '';
  String _sha1 = '';
  String _sha256 = '';

  void _compute() {
    final bytes = utf8.encode(_controller.text);
    setState(() {
      _md5 = md5.convert(bytes).toString();
      _sha1 = sha1.convert(bytes).toString();
      _sha256 = sha256.convert(bytes).toString();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'hash_generator',
      title: 'Hash Generator',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            onChanged: (_) => _compute(),
            decoration: const InputDecoration(hintText: 'Enter text to hash…'),
          ),
          const SizedBox(height: 16),
          _HashRow(label: 'MD5', value: _md5),
          _HashRow(label: 'SHA-1', value: _sha1),
          _HashRow(label: 'SHA-256', value: _sha256),
        ],
      ),
    );
  }
}

class _HashRow extends StatelessWidget {
  const _HashRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SelectableText(
                value.isEmpty ? '—' : value,
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
              if (value.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ToolScaffold.copy(value),
                    child: const Text('Copy'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
