import 'package:flutter/material.dart';

import '../../../widgets/tool_scaffold.dart';

class BinaryTextView extends StatefulWidget {
  const BinaryTextView({super.key});

  @override
  State<BinaryTextView> createState() => _BinaryTextViewState();
}

class _BinaryTextViewState extends State<BinaryTextView> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  int _mode = 0; // 0 text→binary, 1 binary→text
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
        final codes = _input.text.runes
            .map((r) => r.toRadixString(2).padLeft(8, '0'))
            .join(' ');
        _output.text = codes;
      } else {
        final parts = _input.text
            .trim()
            .split(RegExp(r'[\s,]+'))
            .where((p) => p.isNotEmpty);
        final buffer = StringBuffer();
        for (final part in parts) {
          if (!RegExp(r'^[01]+$').hasMatch(part)) {
            throw Exception('Invalid binary: $part');
          }
          buffer.writeCharCode(int.parse(part, radix: 2));
        }
        _output.text = buffer.toString();
      }
      setState(() => _error = null);
      ToolScaffold.logAction(
        toolId: 'binary_text',
        toolName: 'Binary Text',
        action: _mode == 0 ? 'Text → binary' : 'Binary → text',
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _output.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      toolId: 'binary_text',
      title: 'Binary Text',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Text → Binary')),
              ButtonSegment(value: 1, label: Text('Binary → Text')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            maxLines: 5,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: _mode == 0 ? 'Text' : 'Binary bytes',
              hintText: _mode == 0
                  ? 'Hi'
                  : '01001000 01101001',
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
