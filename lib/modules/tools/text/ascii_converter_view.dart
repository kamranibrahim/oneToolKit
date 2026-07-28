import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class AsciiConverterView extends StatefulWidget {
  const AsciiConverterView({super.key});

  @override
  State<AsciiConverterView> createState() => _AsciiConverterViewState();
}

class _AsciiConverterViewState extends State<AsciiConverterView> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  int _mode = 0; // 0 text→codes, 1 codes→text
  int _radix = 10; // 10 decimal, 16 hex
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _convert() {
    try {
      if (_mode == 0) {
        final codes = _input.text.runes.map((r) {
          return _radix == 16
              ? r.toRadixString(16).toUpperCase().padLeft(2, '0')
              : r.toString();
        }).join(' ');
        _output.text = codes;
      } else {
        final parts = _input.text
            .trim()
            .split(RegExp(r'[\s,;]+'))
            .where((p) => p.isNotEmpty);
        final buffer = StringBuffer();
        for (final part in parts) {
          final value = int.parse(part, radix: _radix);
          buffer.writeCharCode(value);
        }
        _output.text = buffer.toString();
      }
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'ascii_converter',
        toolName: 'ASCII Converter',
        action: _mode == 0 ? 'Text → codes' : 'Codes → text',
      );
    } catch (_) {
      setState(() => _error = 'Invalid input for this mode');
      _output.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'ascii_converter',
      title: 'ASCII Converter',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Text → codes')),
              ButtonSegment(value: 1, label: Text('Codes → text')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('Decimal')),
              ButtonSegment(value: 16, label: Text('Hex')),
            ],
            selected: {_radix},
            onSelectionChanged: (s) => setState(() => _radix = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            maxLines: 5,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: _mode == 0 ? 'Text' : 'Code points',
              hintText: _mode == 0
                  ? 'Hello'
                  : (_radix == 16 ? '48 65 6C 6C 6F' : '72 101 108 108 111'),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _convert, child: const Text('Convert')),
          const SizedBox(height: 16),
          TextField(
            controller: _output,
            readOnly: true,
            maxLines: 5,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: const InputDecoration(labelText: 'Output'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _output.text.isEmpty
                ? null
                : () => ToolScaffold.copy(_output.text),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy output'),
          ),
        ],
      ),
    );
  }
}
