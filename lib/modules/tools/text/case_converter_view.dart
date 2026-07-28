import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class CaseConverterView extends StatefulWidget {
  const CaseConverterView({super.key});

  @override
  State<CaseConverterView> createState() => _CaseConverterViewState();
}

class _CaseConverterViewState extends State<CaseConverterView> {
  final _input = TextEditingController();
  final _output = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _apply(String Function(String) transform) {
    _output.text = transform(_input.text);
    setState(() {});
  }

  String _titleCase(String s) => s
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  String _camelCase(String s) {
    final parts = s
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    return parts.first +
        parts.skip(1).map((p) => '${p[0].toUpperCase()}${p.substring(1)}').join();
  }

  String _snakeCase(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  String _kebabCase(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      toolId: 'case_converter',
      title: 'Case Converter',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Enter text…'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('UPPER'), onPressed: () => _apply((s) => s.toUpperCase())),
              ActionChip(label: const Text('lower'), onPressed: () => _apply((s) => s.toLowerCase())),
              ActionChip(label: const Text('Title'), onPressed: () => _apply(_titleCase)),
              ActionChip(label: const Text('camelCase'), onPressed: () => _apply(_camelCase)),
              ActionChip(label: const Text('snake_case'), onPressed: () => _apply(_snakeCase)),
              ActionChip(label: const Text('kebab-case'), onPressed: () => _apply(_kebabCase)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _output,
            maxLines: 5,
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Result'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _output.text.isEmpty
                ? null
                : () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy result'),
          ),
        ],
      ),
    );
  }
}
